import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter_application_1/features/auth/local/auth_local_storage.dart';

class _MemorySecretStorage implements AuthSecretStorage {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

void main() {
  late Directory hiveDirectory;
  late _MemorySecretStorage secretStorage;
  late AuthLocalStorage localStorage;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('auth-storage-');
    Hive.init(hiveDirectory.path);
    secretStorage = _MemorySecretStorage();
    localStorage = AuthLocalStorage(secretStorage: secretStorage);
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('stores password outside of Hive', () async {
    await localStorage.saveAuth(
      {'access_token': 'token'},
      username: 'student@example.com',
      password: 'strong-password',
    );

    final box = await Hive.openBox('auth_session');
    expect(secretStorage.values['saved_password'], 'strong-password');
    expect(box.get('saved_password'), isNull);
    expect(await localStorage.loadPassword(), 'strong-password');
  });

  test('migrates a legacy Hive password into secure storage', () async {
    final box = await Hive.openBox('auth_session');
    await box.put('saved_password', 'legacy-password');

    expect(await localStorage.loadPassword(), 'legacy-password');
    expect(secretStorage.values['saved_password'], 'legacy-password');
    expect(box.get('saved_password'), isNull);
  });

  test('clears the secure password when auth data is cleared', () async {
    await localStorage.saveAuth(
      {'access_token': 'token'},
      username: 'student@example.com',
      password: 'strong-password',
    );

    await localStorage.clearAuth();

    expect(secretStorage.values, isEmpty);
    expect(await localStorage.loadAuth(), isNull);
    expect(await localStorage.loadPassword(), isEmpty);
  });
}
