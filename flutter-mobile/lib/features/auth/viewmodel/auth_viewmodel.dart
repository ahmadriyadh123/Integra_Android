import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../models/auth_model.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';
import '../../../services/tenant_api_config.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository repository;
  late final StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription;

  AuthViewModel({
    required this.repository,
    Stream<List<ConnectivityResult>>? connectivityChanges,
  }) {
    _connectivitySubscription = connectivityChanges?.listen((results) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        unawaited(_retryPendingPasswordChange());
      }
    });
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AuthResult? _authResult;
  AuthResult? get authResult => _authResult;

  bool _passwordChangePending = false;
  bool get passwordChangePending => _passwordChangePending;

  bool _isSyncingPasswordChange = false;
  bool get isSyncingPasswordChange => _isSyncingPasswordChange;

  String? _passwordChangeSyncMessage;
  String? get passwordChangeSyncMessage => _passwordChangeSyncMessage;

  bool get isLoggedIn => _authResult != null;
  String get token => _authResult?.accessToken ?? '';
  UserProfile? get user => _authResult?.user;

  Future<bool> login(String username, String password) async {
    if (_isLoading) return false;
    if (username.trim().isEmpty || password.trim().isEmpty) {
      _errorMessage = 'Username dan password tidak boleh kosong';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AuthResult result;
      var authenticatedOffline = false;
      try {
        result = await repository.login(username.trim(), password);
      } on AuthNetworkException {
        final offlineResult = await repository.loginOffline(
          username.trim(),
          password,
        );
        if (offlineResult == null) {
          _authResult = null;
          _errorMessage =
              'Tidak dapat terhubung ke server. Login offline hanya tersedia '
              'dengan username dan password yang pernah berhasil digunakan.';
          return false;
        }
        result = offlineResult;
        authenticatedOffline = true;
      }

      await repository.saveAuth(
        {
          'access_token': result.accessToken,
          'token_type': result.tokenType,
          'user': result.user.toJson(),
        },
        username: username.trim(),
        password: password,
      );

      _authResult = result;
      if (authenticatedOffline) {
        unawaited(_refreshPendingPasswordChangeState());
      } else {
        final resolvedPending = await repository
            .resolvePendingPasswordChangeAfterLogin(password);
        if (resolvedPending) {
          _passwordChangePending = false;
          _passwordChangeSyncMessage =
              'Password baru terverifikasi saat login; antrean sinkronisasi selesai.';
        } else {
          unawaited(_refreshPendingPasswordChangeState());
        }
      }
      return true;
    } on TenantTokenMismatchException catch (error) {
      _authResult = null;
      await repository.clearAuth();
      _errorMessage = error.message.toString();
      return false;
    } catch (e) {
      _authResult = null;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Restore session dari Hive tanpa API call (offline-first).
  /// Hanya memvalidasi ke API jika ada koneksi internet.
  Future<bool> restoreSessionFromHive() async {
    try {
      // Pulihkan data lokal lebih dulu agar login tidak menunggu jaringan.
      final authData = await repository.loadAuth();
      if (authData == null) {
        return false;
      }

      try {
        _authResult = AuthResult.fromJson(authData);
      } catch (_) {
        // Jika parsing gagal, clear dan restart login
        await repository.clearAuth();
        return false;
      }

      if (!repository.isTokenForSelectedSchool(_authResult!.accessToken)) {
        _authResult = null;
        await repository.clearAuth();
        _errorMessage = 'Sekolah yang dipilih berubah. Silakan login kembali.';
        notifyListeners();
        return false;
      }

      unawaited(_refreshPendingPasswordChangeState());
      // Validasi token berjalan terpisah agar pemulihan session tetap cepat.
      _validateSessionInBackground();

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Validasi session token secara lokal (decode JWT exp claim).
  /// Tidak ada network request — aman untuk semua platform/device.
  Future<void> _validateSessionInBackground() async {
    if (token.isEmpty) return;

    try {
      // Decode payload hanya untuk membaca masa berlaku token.
      final parts = token.split('.');
      if (parts.length != 3) {
        await logout();
        return;
      }

      // JWT memakai Base64 URL tanpa padding wajib.
      String payload = parts[1];
      final remainder = payload.length % 4;
      if (remainder != 0) payload += '=' * (4 - remainder);

      final decoded = String.fromCharCodes(base64Url.decode(payload));
      final Map<String, dynamic> claims =
          json.decode(decoded) as Map<String, dynamic>;

      final exp = claims['exp'];
      if (exp == null) return; // Tidak ada exp → anggap valid

      final expiry = DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
      if (DateTime.now().isAfter(expiry)) {
        // Token kedaluwarsa tidak boleh dipakai untuk melanjutkan session.
        await logout();
        _errorMessage = 'Session telah berakhir. Silakan login kembali.';
        notifyListeners();
      }
    } catch (_) {
      // Jika decode gagal karena format aneh, biarkan session tetap aktif
      // Tidak perlu logout karena bisa jadi false positive
    }
  }

  Future<void> logout() async {
    _authResult = null;
    _errorMessage = null;
    await repository.clearSession();
    notifyListeners();
  }

  Future<PasswordChangeStatus> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _passwordChangeSyncMessage = null;
    final status = await repository.changePassword(
      token: token,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    _passwordChangePending = status == PasswordChangeStatus.queued;
    if (_passwordChangePending) {
      _passwordChangeSyncMessage =
          'Perubahan tersimpan dengan aman dan menunggu koneksi untuk disinkronkan.';
    }
    notifyListeners();
    return status;
  }

  Future<void> _refreshPendingPasswordChangeState() async {
    try {
      _passwordChangePending = await repository.hasPendingPasswordChange();
      if (_passwordChangePending) {
        _passwordChangeSyncMessage =
            'Perubahan password menunggu sinkronisasi.';
        notifyListeners();
        unawaited(_retryPendingPasswordChange());
      }
    } catch (error) {
      _passwordChangeSyncMessage =
          'Antrean perubahan password tidak dapat dibaca: $error';
      notifyListeners();
    }
  }

  Future<void> _retryPendingPasswordChange() async {
    if (_isSyncingPasswordChange || !isLoggedIn || !_passwordChangePending) {
      return;
    }

    _isSyncingPasswordChange = true;
    notifyListeners();
    try {
      final synced = await repository.syncPendingPasswordChange(token);
      if (synced) {
        _passwordChangePending = false;
        _passwordChangeSyncMessage =
            'Password berhasil diperbarui dan disinkronkan ke server.';
      }
    } catch (error) {
      _passwordChangePending = true;
      _passwordChangeSyncMessage =
          'Sinkronisasi perubahan password gagal: '
          '${error.toString().replaceFirst('Exception: ', '')}';
    } finally {
      _isSyncingPasswordChange = false;
      notifyListeners();
    }
  }

  Future<void> cancelPendingPasswordChange() async {
    if (_isSyncingPasswordChange || !_passwordChangePending) return;
    await repository.cancelPendingPasswordChange();
    _passwordChangePending = false;
    _passwordChangeSyncMessage =
        'Permintaan perubahan password tertunda telah dibatalkan.';
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<int> loadLastTabIndex() => repository.getLastTabIndex();
  Future<void> saveLastTabIndex(int index) => repository.setLastTabIndex(index);
  Future<String> loadUsername() => repository.loadUsername();
  Future<String> loadPassword() => repository.loadPassword();

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
