import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  static const String _keyUsername = 'saved_username';
  static const String _keyPassword = 'saved_password';

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
    await box.put(_keyAuth, authData);
    await box.put(_keyUsername, username);
    await box.delete(_keyPassword);
  }

  /// Load auth result dari Hive (untuk offline restore tanpa API call).
  Future<Map<String, dynamic>?> loadAuth() async {
    final box = await _box();
    final raw = box.get(_keyAuth);
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

  static const String _keyLastTabIndex = 'last_tab_index';

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
      box.delete(_keyUsername),
      box.delete(_keyPassword),
      box.delete(_keyLastTabIndex),
      _secretStorage.delete(_keyPassword),
    ]);
  }

  Future<bool> hasSavedAuth() async {
    final auth = await loadAuth();
    return auth != null;
  }
}
