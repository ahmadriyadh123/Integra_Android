import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_application_1/features/auth/local/auth_local_storage.dart';
import 'package:flutter_application_1/services/authenticated_http_client.dart';
import 'package:flutter_application_1/services/tenant_api_config.dart';

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

String _jwtForSchool(
  int schoolId, {
  int expiry = 4102444800,
  String signature = 'signature',
}) {
  String segment(String value) =>
      base64Url.encode(utf8.encode(value)).replaceAll('=', '');
  return [
    segment('{"alg":"HS256","typ":"JWT"}'),
    segment('{"school_id":$schoolId,"exp":$expiry}'),
    segment(signature),
  ].join('.');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory hiveDirectory;
  late _MemorySecretStorage secrets;
  late AuthLocalStorage storage;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('refresh-client-');
    Hive.init(hiveDirectory.path);
    secrets = _MemorySecretStorage();
    storage = AuthLocalStorage(secretStorage: secrets);
    await storage.saveAuth(
      {
        'access_token': _jwtForSchool(1),
        'refresh_token': 'old-refresh',
        'token_type': 'bearer',
        'user': {'user_id': 5, 'username': 'student'},
      },
      username: 'student',
      password: 'password',
    );
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test(
    'refreshes once after 401 and retries with rotated credentials',
    () async {
      final oldAccess = _jwtForSchool(1);
      final newAccess = _jwtForSchool(1, signature: 'rotated');
      var refreshRequests = 0;
      var apiRequests = 0;
      final config = TenantApiConfig(schoolId: '1');
      final client = AuthenticatedHttpClient(
        baseUrl: 'https://example.com/api/v1',
        tenantApiConfig: config,
        authStorage: storage,
        innerClient: MockClient((request) async {
          if (request.url.path == '/api/v1/auth/refresh') {
            refreshRequests++;
            expect(jsonDecode(request.body), {'refresh_token': 'old-refresh'});
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'access_token': newAccess,
                  'refresh_token': 'new-refresh',
                  'token_type': 'bearer',
                },
              }),
              200,
            );
          }
          apiRequests++;
          if (apiRequests == 1) return http.Response('Unauthorized', 401);
          expect(request.headers['authorization'], 'Bearer $newAccess');
          return http.Response('{"success":true}', 200);
        }),
      );

      final response = await client.get(
        Uri.parse('https://example.com/api/v1/profile/me'),
        headers: config.headers(token: oldAccess),
      );

      expect(response.statusCode, 200);
      expect(refreshRequests, 1);
      expect(apiRequests, 2);
      expect((await storage.loadAuth())?['access_token'], newAccess);
      expect(await storage.loadRefreshToken(), 'new-refresh');
      final box = await Hive.openBox('auth_session');
      expect(
        (box.get('auth_result') as Map).containsKey('refresh_token'),
        false,
      );
      client.close();
    },
  );

  test('concurrent 401 responses share one refresh request', () async {
    var refreshRequests = 0;
    var apiRequests = 0;
    final config = TenantApiConfig(schoolId: '1');
    final currentAccess = _jwtForSchool(1);
    final client = AuthenticatedHttpClient(
      baseUrl: 'https://example.com/api/v1',
      tenantApiConfig: config,
      authStorage: storage,
      innerClient: MockClient((request) async {
        if (request.url.path == '/api/v1/auth/refresh') {
          refreshRequests++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'access_token': currentAccess,
                'refresh_token': 'rotated-refresh',
              },
            }),
            200,
          );
        }
        apiRequests++;
        if (apiRequests <= 2) return http.Response('Unauthorized', 401);
        return http.Response('OK', 200);
      }),
    );

    final responses = await Future.wait([
      client.get(
        Uri.parse('https://example.com/api/v1/profile/me'),
        headers: config.headers(token: currentAccess),
      ),
      client.get(
        Uri.parse('https://example.com/api/v1/elearning/courses'),
        headers: config.headers(token: currentAccess),
      ),
    ]);

    expect(responses.map((response) => response.statusCode), [200, 200]);
    expect(refreshRequests, 1);
    client.close();
  });

  test('invalid refresh tokens clear local session state', () async {
    final config = TenantApiConfig(schoolId: '1');
    var expiredCallbacks = 0;
    config.onSessionExpired = () async {
      expiredCallbacks++;
      await storage.clearStoredTokens();
    };
    final client = AuthenticatedHttpClient(
      baseUrl: 'https://example.com/api/v1',
      tenantApiConfig: config,
      authStorage: storage,
      innerClient: MockClient((request) async {
        if (request.url.path == '/api/v1/auth/refresh') {
          return http.Response('{"detail":"Refresh token tidak berlaku"}', 401);
        }
        return http.Response('Unauthorized', 401);
      }),
    );

    final response = await client.get(
      Uri.parse('https://example.com/api/v1/profile/me'),
      headers: config.headers(token: _jwtForSchool(1)),
    );

    expect(response.statusCode, 401);
    expect(expiredCallbacks, 1);
    expect(await storage.loadAuth(), isNull);
    expect(await storage.loadRefreshToken(), isNull);
    client.close();
  });
}
