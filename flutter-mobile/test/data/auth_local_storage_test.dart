import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter_application_1/data/local/auth/auth_local_storage.dart';

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

  test('stores refresh tokens securely and updates access tokens on rotation', () async {
    await localStorage.saveAuth(
      {
        'access_token': 'old-access',
        'refresh_token': 'old-refresh',
        'user': {'user_id': 1},
      },
      username: 'student',
      password: 'password',
    );

    final box = await Hive.openBox('auth_session');
    expect(secretStorage.values['refresh_token'], 'old-refresh');
    expect((box.get('auth_result') as Map).containsKey('refresh_token'), false);
    expect((await localStorage.loadAuth())?['refresh_token'], 'old-refresh');

    await localStorage.saveRefreshedTokens(
      accessToken: 'new-access',
      refreshToken: 'new-refresh',
    );

    expect((await localStorage.loadAuth())?['access_token'], 'new-access');
    expect(await localStorage.loadRefreshToken(), 'new-refresh');
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

  test('clears session while retaining credentials for offline login', () async {
    await localStorage.saveAuth(
      {'access_token': 'token'},
      username: 'student@example.com',
      password: 'strong-password',
    );

    await localStorage.clearSession();

    expect(await localStorage.loadAuth(), isNull);
    expect(await localStorage.loadOfflineAuth(), {'access_token': 'token'});
    expect(await localStorage.loadUsername(), 'student@example.com');
    expect(await localStorage.loadPassword(), 'strong-password');
  });

  test('removes offline login snapshot when credentials are cleared', () async {
    await localStorage.saveAuth(
      {'access_token': 'token'},
      username: 'student@example.com',
      password: 'strong-password',
    );

    await localStorage.clearAuth();

    expect(await localStorage.loadOfflineAuth(), isNull);
  });

  test(
    'stores a pending password change and completes it after sync',
    () async {
      await localStorage.queuePasswordChange(
        currentPassword: 'old-password',
        newPassword: 'new-password',
      );

      final pending = await localStorage.loadPendingPasswordChange();
      expect(pending?.currentPassword, 'old-password');
      expect(pending?.newPassword, 'new-password');

      await localStorage.completePasswordChange('new-password');

      expect(await localStorage.loadPendingPasswordChange(), isNull);
      expect(await localStorage.loadPassword(), 'new-password');
    },
  );

  test('preserves pending password change when clearing a session', () async {
    await localStorage.queuePasswordChange(
      currentPassword: 'old-password',
      newPassword: 'new-password',
    );

    await localStorage.clearAuth();

    expect(await localStorage.loadPendingPasswordChange(), isNotNull);
  });
}
