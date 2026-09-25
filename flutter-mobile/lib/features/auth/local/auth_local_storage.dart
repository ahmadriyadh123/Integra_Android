import 'package:hive_flutter/hive_flutter.dart';

class AuthLocalStorage {
  static const String _boxName = 'auth_session';
  static const String _keyAuth = 'auth_result';
  static const String _keyUsername = 'saved_username';
  static const String _keyPassword = 'saved_password';

  Future<Box> _box() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  /// Simpan lengkap auth result + credentials untuk offline-first login.
  Future<void> saveAuth(Map<String, dynamic> authData, {
    required String username,
    required String password,
  }) async {
    final box = await _box();
    await box.put(_keyAuth, authData);
    await box.put(_keyUsername, username);
    await box.put(_keyPassword, password);
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
    final value = box.get(_keyPassword);
    return value is String ? value : '';
  }

  Future<void> updateSavedPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final box = await _box();
    final savedPassword = box.get(_keyPassword);

    if (savedPassword is! String) {
      await box.put(_keyPassword, newPassword);
      return;
    }

    if (savedPassword != currentPassword) {
      throw Exception('Password lama tidak sesuai dengan data lokal.');
    }

    await box.put(_keyPassword, newPassword);
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
    await box.delete(_keyAuth);
    await box.delete(_keyUsername);
    await box.delete(_keyPassword);
    await box.delete(_keyLastTabIndex);
  }

  Future<bool> hasSavedAuth() async {
    final auth = await loadAuth();
    return auth != null;
  }
}
