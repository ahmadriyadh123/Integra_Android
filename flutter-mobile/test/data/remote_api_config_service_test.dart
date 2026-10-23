import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/config/api/remote_api_config_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loads and normalizes a secure API base URL', () async {
    final service = RemoteApiConfigService(
      client: MockClient((request) async {
        expect(request.url.toString(), RemoteApiConfigService.configUrl);
        return http.Response(
          jsonEncode({
            'api_base_url': 'https://api.example.com/mobile-api/api/v1/',
          }),
          200,
        );
      }),
    );

    expect(
      await service.fetchBaseUrl(),
      'https://api.example.com/mobile-api/api/v1',
    );
  });

  test('rejects non-HTTPS API base URLs', () async {
    final service = RemoteApiConfigService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'api_base_url': 'http://api.example.com/api/v1'}),
          200,
        ),
      ),
    );

    expect(service.fetchBaseUrl(), throwsA(isA<RemoteApiConfigException>()));
  });

  test('rejects API base URLs without the API version path', () async {
    final service = RemoteApiConfigService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'api_base_url': 'https://api.example.com/'}),
          200,
        ),
      ),
    );

    expect(service.fetchBaseUrl(), throwsA(isA<RemoteApiConfigException>()));
  });

  test('rejects unsuccessful config responses', () async {
    final service = RemoteApiConfigService(
      client: MockClient((_) async => http.Response('', 503)),
    );

    expect(service.fetchBaseUrl(), throwsA(isA<RemoteApiConfigException>()));
  });

  test('rejects malformed config JSON', () async {
    final service = RemoteApiConfigService(
      client: MockClient((_) async => http.Response('not-json', 200)),
    );

    expect(service.fetchBaseUrl(), throwsA(isA<RemoteApiConfigException>()));
  });
}
