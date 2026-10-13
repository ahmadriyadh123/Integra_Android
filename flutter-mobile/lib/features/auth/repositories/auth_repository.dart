import '../local/auth_local_storage.dart';
import '../models/auth_model.dart';
import '../services/auth_service.dart';
import '../../../services/tenant_api_config.dart';

enum PasswordChangeStatus { completed, queued }

class AuthRepository {
  final AuthService apiService;
  final AuthLocalStorage localStorageService;

  AuthRepository({required this.apiService, required this.localStorageService});

  Future<AuthResult> login(String username, String password) async {
    final data = await apiService.login(username, password);
    final token = data['access_token'];
    final tokenType = data['token_type'];
    if (token is! String ||
        tokenType is! String ||
        tokenType.toLowerCase() != 'bearer' ||
        !isTokenForSelectedSchool(token)) {
      throw const TenantTokenMismatchException();
    }

    return AuthResult.fromJson(data);
  }

  Future<AuthResult?> loginOffline(String username, String password) async {
    final savedUsername = await localStorageService.loadUsername();
    final savedPassword = await localStorageService.loadPassword();
    if (username.trim() != savedUsername || password != savedPassword) {
      return null;
    }

    final authData = await localStorageService.loadOfflineAuth();
    if (authData == null) return null;

    final token = authData['access_token'];
    final tokenType = authData['token_type'];
    if (token is! String ||
        tokenType is! String ||
        tokenType.toLowerCase() != 'bearer' ||
        !isTokenForSelectedSchool(token)) {
      throw const TenantTokenMismatchException();
    }

    return AuthResult.fromJson(authData);
  }

  bool isTokenForSelectedSchool(String token) =>
      apiService.tenantApiConfig.tokenMatchesSelectedSchool(token);

  /// Validasi session token ke backend.
  /// Throw exception jika token invalid atau expired.
  Future<void> validateSession(String token) => apiService.validateToken(token);

  Future<PasswordChangeStatus> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final pending = await localStorageService.loadPendingPasswordChange();
    if (pending != null) {
      throw StateError(
        'Perubahan password sebelumnya masih menunggu sinkronisasi.',
      );
    }

    try {
      await apiService.changePassword(
        token: token,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      await localStorageService.completePasswordChange(newPassword);
      return PasswordChangeStatus.completed;
    } on AuthNetworkException {
      final savedPassword = await localStorageService.loadPassword();
      if (savedPassword != currentPassword) {
        rethrow;
      }
      await localStorageService.queuePasswordChange(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return PasswordChangeStatus.queued;
    }
  }

  Future<bool> syncPendingPasswordChange(String token) async {
    final pending = await localStorageService.loadPendingPasswordChange();
    if (pending == null) return false;

    await apiService.changePassword(
      token: token,
      currentPassword: pending.currentPassword,
      newPassword: pending.newPassword,
    );
    await localStorageService.completePasswordChange(pending.newPassword);
    return true;
  }

  Future<bool> hasPendingPasswordChange() async =>
      await localStorageService.loadPendingPasswordChange() != null;

  Future<bool> resolvePendingPasswordChangeAfterLogin(
    String authenticatedPassword,
  ) async {
    final pending = await localStorageService.loadPendingPasswordChange();
    if (pending == null || authenticatedPassword != pending.newPassword) {
      return false;
    }
    await localStorageService.completePasswordChange(pending.newPassword);
    return true;
  }

  Future<void> cancelPendingPasswordChange() =>
      localStorageService.cancelPendingPasswordChange();

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

  Future<Map<String, dynamic>?> loadOfflineAuth() {
    return localStorageService.loadOfflineAuth();
  }

  /// Clear auth data from local storage
  Future<void> clearAuth() {
    return localStorageService.clearAuth();
  }

  Future<void> clearSession() {
    return localStorageService.clearSession();
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
