import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class PendingPasswordChange {
  const PendingPasswordChange({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  Map<String, dynamic> toJson() => {
    'current_password': currentPassword,
    'new_password': newPassword,
  };

  factory PendingPasswordChange.fromJson(Map<String, dynamic> json) {
    final currentPassword = json['current_password'];
    final newPassword = json['new_password'];
    if (currentPassword is! String ||
        currentPassword.isEmpty ||
        newPassword is! String ||
        newPassword.isEmpty) {
      throw const FormatException('Antrean perubahan password tidak valid.');
    }
    return PendingPasswordChange(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}

abstract interface class AuthSecretStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterAuthSecretStorage implements AuthSecretStorage {
  FlutterAuthSecretStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class AuthLocalStorage {
  static const String _boxName = 'auth_session';
  static const String _keyAuth = 'auth_result';
  static const String _keyOfflineAuth = 'offline_auth_result';
  static const String _keyUsername = 'saved_username';
  static const String _keyPassword = 'saved_password';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyPendingPasswordChange = 'pending_password_change';

  AuthLocalStorage({AuthSecretStorage? secretStorage})
    : _secretStorage = secretStorage ?? FlutterAuthSecretStorage();

  final AuthSecretStorage _secretStorage;

  Future<Box> _box() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  /// Save the session in Hive and credentials in secure platform storage.
  Future<void> saveAuth(
    Map<String, dynamic> authData, {
    required String username,
    required String password,
  }) async {
    final box = await _box();
    await _secretStorage.write(_keyPassword, password);
    final storedAuth = Map<String, dynamic>.from(authData)
      ..remove('refresh_token');
    final refreshToken = authData['refresh_token'];
    if (refreshToken is String && refreshToken.isNotEmpty) {
      await _secretStorage.write(_keyRefreshToken, refreshToken);
    } else {
      await _secretStorage.delete(_keyRefreshToken);
    }
    await box.put(_keyAuth, storedAuth);
    await box.put(_keyOfflineAuth, storedAuth);
    await box.put(_keyUsername, username);
    await box.delete(_keyPassword);
  }

  /// Load auth result dari Hive (untuk offline restore tanpa API call).
  Future<Map<String, dynamic>?> loadAuth() async {
    final box = await _box();
    final raw = box.get(_keyAuth);
    if (raw is! Map) return null;
    final auth = Map<String, dynamic>.from(raw);
    final refreshToken = await _secretStorage.read(_keyRefreshToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      auth['refresh_token'] = refreshToken;
    }
    return auth;
  }

  Future<String?> loadRefreshToken() => _secretStorage.read(_keyRefreshToken);

  Future<void> saveRefreshedTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final box = await _box();
    for (final key in [_keyAuth, _keyOfflineAuth]) {
      final raw = box.get(key);
      if (raw is Map) {
        final auth = Map<String, dynamic>.from(raw)
          ..['access_token'] = accessToken;
        await box.put(key, auth);
      }
    }
    await _secretStorage.write(_keyRefreshToken, refreshToken);
  }

  Future<Map<String, dynamic>?> loadOfflineAuth() async {
    final box = await _box();
    final raw = box.get(_keyOfflineAuth) ?? box.get(_keyAuth);
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  Future<String> loadUsername() async {
    final box = await _box();
    final value = box.get(_keyUsername);
    return value is String ? value : '';
  }

  Future<String> loadPassword() async {
    final box = await _box();
    final securePassword = await _secretStorage.read(_keyPassword);
    if (securePassword != null) return securePassword;

    // Migrate passwords written by older versions from Hive to secure storage.
    final legacyPassword = box.get(_keyPassword);
    if (legacyPassword is! String) {
      if (legacyPassword != null) await box.delete(_keyPassword);
      return '';
    }

    await _secretStorage.write(_keyPassword, legacyPassword);
    await box.delete(_keyPassword);
    return legacyPassword;
  }

  Future<void> queuePasswordChange({
    required String currentPassword,
    required String newPassword,
  }) => _secretStorage.write(
    _keyPendingPasswordChange,
    json.encode(
      PendingPasswordChange(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ).toJson(),
    ),
  );

  Future<PendingPasswordChange?> loadPendingPasswordChange() async {
    final raw = await _secretStorage.read(_keyPendingPasswordChange);
    if (raw == null) return null;
    final decoded = json.decode(raw);
    if (decoded is! Map) {
      throw const FormatException('Antrean perubahan password tidak valid.');
    }
    return PendingPasswordChange.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<void> completePasswordChange(String newPassword) async {
    await _secretStorage.write(_keyPassword, newPassword);
    await _secretStorage.delete(_keyPendingPasswordChange);
  }

  Future<void> cancelPendingPasswordChange() =>
      _secretStorage.delete(_keyPendingPasswordChange);

  static const String _keyLastTabIndex = 'last_tab_index';

  Future<void> clearSession() async {
    final box = await _box();
    await Future.wait([
      box.delete(_keyAuth),
      box.delete(_keyLastTabIndex),
      _secretStorage.delete(_keyRefreshToken),
    ]);
  }

  Future<void> clearStoredTokens() async {
    final box = await _box();
    await Future.wait([
      box.delete(_keyAuth),
      box.delete(_keyOfflineAuth),
      box.delete(_keyLastTabIndex),
      _secretStorage.delete(_keyRefreshToken),
    ]);
  }

  Future<void> saveLastTabIndex(int index) async {
    final box = await _box();
    await box.put(_keyLastTabIndex, index);
  }

  Future<int> loadLastTabIndex() async {
    final box = await _box();
    final value = box.get(_keyLastTabIndex);
    return value is int ? value : 0;
  }

  Future<void> clearAuth() async {
    final box = await _box();
    await Future.wait([
      box.delete(_keyAuth),
      box.delete(_keyOfflineAuth),
      box.delete(_keyUsername),
      box.delete(_keyPassword),
      box.delete(_keyLastTabIndex),
      _secretStorage.delete(_keyPassword),
      _secretStorage.delete(_keyRefreshToken),
    ]);
  }

  Future<bool> hasSavedAuth() async {
    final auth = await loadAuth();
    return auth != null;
  }
}
