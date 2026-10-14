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
          'refresh_token': result.refreshToken,
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
      if (!await _validateRestoredSession()) return false;

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Check expiry locally, then confirm the cached token with the API.
  /// Network failures keep the cached session available for offline use.
  Future<bool> _validateRestoredSession() async {
    final cachedToken = token;
    if (cachedToken.isEmpty) return false;

    try {
      final parts = cachedToken.split('.');
      if (parts.length != 3) {
        throw const FormatException('Token JWT tidak valid.');
      }

      String payload = parts[1];
      final remainder = payload.length % 4;
      if (remainder != 0) payload += '=' * (4 - remainder);

      final decoded = String.fromCharCodes(base64Url.decode(payload));
      final Map<String, dynamic> claims =
          json.decode(decoded) as Map<String, dynamic>;

      final exp = claims['exp'];
      if (exp != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
        if (DateTime.now().isAfter(expiry)) {
          return _refreshExpiredSession();
        }
      }
    } on FormatException {
      // The API still validates malformed or unreadable claims below.
    } on TypeError {
      // The API still validates claims with an unexpected local shape.
    }

    try {
      await repository.validateSession(cachedToken);
      return true;
    } on AuthSessionInvalidException catch (error) {
      if (_authResult == null) return false;
      try {
        _authResult = await repository.refreshSession(_authResult!);
        return true;
      } on AuthSessionInvalidException {
        await _clearInvalidStoredSession(error.message);
        return false;
      } on TenantTokenMismatchException catch (refreshError) {
        await _clearInvalidStoredSession(refreshError.message);
        return false;
      } on AuthNetworkException {
        return true;
      }
    } catch (_) {
      return true;
    }
  }

  Future<bool> _refreshExpiredSession() async {
    try {
      _authResult = await repository.refreshSession(_authResult!);
      return true;
    } on AuthSessionInvalidException catch (error) {
      await _clearInvalidStoredSession(error.message);
      return false;
    } on TenantTokenMismatchException catch (error) {
      await _clearInvalidStoredSession(error.message);
      return false;
    } on AuthNetworkException {
      return true;
    }
  }

  Future<void> _clearInvalidStoredSession(String message) async {
    _authResult = null;
    await repository.clearStoredTokens();
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> handleSessionExpired() async {
    if (_authResult == null) {
      await repository.clearStoredTokens();
      return;
    }
    await _clearInvalidStoredSession(
      'Sesi login tidak berlaku. Silakan login kembali.',
    );
  }

  Future<void> logout() async {
    try {
      await repository.revokeRefreshToken(_authResult?.refreshToken);
    } catch (_) {
      // Local logout must still complete when the server is unreachable.
    }
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
