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
      // 1. Coba load auth result dari Hive (offline)
      final authData = await localStorage.loadAuth();
      if (authData == null) {
        return false;
      }

      // 2. Parse auth result dari local storage
      try {
        _authResult = AuthResult.fromJson(authData);
      } catch (_) {
        // Jika parsing gagal, clear dan restart login
        await localStorage.clearAuth();
        return false;
      }

      // 3. Optional: Validasi ke API di background jika ada koneksi
      // Jika validasi gagal, logout otomatis
      _validateSessionInBackground();

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Validasi session ke API di background (non-blocking).
  /// Jika gagal, logout otomatis dan user harus login ulang.
  Future<void> _validateSessionInBackground() async {
    if (token.isEmpty) return;

    try {
      // Coba hit endpoint dummy untuk validasi token
      // Bisa menggunakan GET /profile atau endpoint lain yang ringan
      await repository.validateSession(token);
      // Validasi berhasil, session masih valid
    } catch (_) {
      // Token invalid atau expired, logout otomatis
      await logout();
      _errorMessage = 'Session expired. Silakan login kembali.';
      notifyListeners();
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
