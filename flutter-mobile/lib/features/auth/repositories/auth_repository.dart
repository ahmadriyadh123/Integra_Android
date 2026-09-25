import 'dart:async';
import 'dart:io';

import '../local/auth_local_storage.dart';
import '../models/auth_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService apiService;
  final AuthLocalStorage localStorageService;

  AuthRepository({
    required this.apiService,
    required this.localStorageService,
  });

  Future<AuthResult> login(String username, String password) async {
    try {
      final data = await apiService.login(username, password);
      return AuthResult.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Validasi session token ke backend.
  /// Throw exception jika token invalid atau expired.
  Future<void> validateSession(String token) async {
    try {
      await apiService.validateToken(token);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await apiService.changePassword(
        token: token,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (error) {
      final message = error.toString().toLowerCase();
      final isOfflineFallback = error is TimeoutException ||
          error is SocketException ||
          error is HttpException ||
          error is FormatException && message.contains('offline');

      if (!isOfflineFallback) {
        rethrow;
      }

      await localStorageService.updateSavedPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    }
  }

  /// Save auth data and credentials to local storage
  Future<void> saveAuth(
    Map<String, dynamic> authData, {
    required String username,
    required String password,
  }) {
    return localStorageService.saveAuth(
      authData,
      username: username,
      password: password,
    );
  }

  /// Load auth data from local storage
  Future<Map<String, dynamic>?> loadAuth() {
    return localStorageService.loadAuth();
  }

  /// Clear auth data from local storage
  Future<void> clearAuth() {
    return localStorageService.clearAuth();
  }

  /// Load saved username from local storage
  Future<String> loadUsername() {
    return localStorageService.loadUsername();
  }

  /// Load saved password from local storage
  Future<String> loadPassword() {
    return localStorageService.loadPassword();
  }

  /// Load the last accessed tab index from local storage
  Future<int> getLastTabIndex() async {
    return localStorageService.loadLastTabIndex();
  }

  /// Save the last accessed tab index to local storage
  Future<void> setLastTabIndex(int index) async {
    return localStorageService.saveLastTabIndex(index);
  }
}
