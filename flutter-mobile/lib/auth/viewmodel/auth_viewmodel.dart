import 'dart:convert';
import 'package:flutter/material.dart';
import '../local/auth_local_storage.dart';
import '../models/auth_model.dart';
import '../repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository repository;
  final AuthLocalStorage localStorage;

  AuthViewModel({
    required this.repository,
    required this.localStorage,
  });

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AuthResult? _authResult;
  AuthResult? get authResult => _authResult;

  bool get isLoggedIn => _authResult != null;
  String get token => _authResult?.accessToken ?? '';
  UserProfile? get user => _authResult?.user;

  Future<bool> login(String username, String password) async {
    if (username.trim().isEmpty || password.trim().isEmpty) {
      _errorMessage = 'Username dan password tidak boleh kosong';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.login(username.trim(), password);
      _authResult = result;

      await localStorage.saveAuth(
        {
          'access_token': result.accessToken,
          'token_type': result.tokenType,
          'user': {
            'user_id': result.user.userId,
            'partner_id': result.user.partnerId,
            'name': result.user.name,
            'username': result.user.username,
            'email': result.user.email,
            'class_name': result.user.className,
            'jenjang': result.user.jenjang,
          },
        },
        username: username.trim(),
        password: password,
      );

      return true;
    } catch (e) {
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
      final authData = await localStorage.loadAuth();
      if (authData == null) {
        return false;
      }

      try {
        _authResult = AuthResult.fromJson(authData);
      } catch (_) {
        // Jika parsing gagal, clear dan restart login
        await localStorage.clearAuth();
        return false;
      }

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

      final decoded = String.fromCharCodes(
          base64Url.decode(payload));
      final Map<String, dynamic> claims =
          json.decode(decoded) as Map<String, dynamic>;

      final exp = claims['exp'];
      if (exp == null) return; // Tidak ada exp → anggap valid

      final expiry =
          DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
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
    await localStorage.clearAuth();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
