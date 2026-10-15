import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/elearning/services/elearning_service.dart';
import 'package:flutter_application_1/services/tenant_api_config.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _token() {
  String encodeSegment(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return [
    encodeSegment({'alg': 'HS256'}),
    encodeSegment({'school_id': 4, 'uid': 10}),
    encodeSegment('signature'),
  ].join('.');
}

void main() {
  test('all E-Learning API calls use the injected HTTP client', () async {
    final requests = <String>[];
    final client = MockClient((request) async {
      requests.add('${request.method} ${request.url.path}');
      expect(request.headers['X-School-ID'], '4');

      final response = switch (request.url.path) {
        '/api/v1/elearning/courses/sync' => {
          'success': true,
          'data': {
            'items': [],
            'removed_ids': [],
            'next_cursor': 'cursor',
            'full_sync': true,
          },
        },
        '/api/v1/elearning/courses' => {'success': true, 'data': []},
        '/api/v1/elearning/courses/5' => {
          'success': true,
          'data': {'id': 5, 'slides': []},
        },
        '/api/v1/elearning/content/51' => {
          'success': true,
          'url': 'https://example.com/content/51',
        },
        '/api/v1/elearning/courses/5/slides/51/progress' => {'success': true},
        '/api/v1/elearning/courses/5/messages' when request.method == 'GET' => {
          'success': true,
          'data': [],
        },
        '/api/v1/elearning/courses/5/messages' => {'success': true},
        _ => throw StateError('Unexpected request: ${request.url}'),
      };
      return http.Response(
        jsonEncode(response),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = ElearningService(
      baseUrl: 'https://example.com/api/v1',
      tenantApiConfig: TenantApiConfig(schoolId: '4'),
      httpClient: client,
    );
    final token = _token();

    await service.syncCourses(token);
    await service.fetchCourses(token);
    await service.fetchCourseDetail(token, 5);
    await service.fetchSlideContent(token, 51);
    await service.markSlideCompleted(token, 5, 51, source: 'mobile');
    await service.fetchCourseMessages(token, 5);
    await service.sendCourseMessage(token, 5, 'Halo');

    expect(requests, [
      'GET /api/v1/elearning/courses/sync',
      'GET /api/v1/elearning/courses',
      'GET /api/v1/elearning/courses/5',
      'GET /api/v1/elearning/content/51',
      'POST /api/v1/elearning/courses/5/slides/51/progress',
      'GET /api/v1/elearning/courses/5/messages',
      'POST /api/v1/elearning/courses/5/messages',
    ]);
    client.close();
  });

  test('rejects API payloads that have an unexpected shape', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'success': true,
          'data': {'unexpected': 'object'},
        }),
        200,
      ),
    );
    final service = ElearningService(
      baseUrl: 'https://example.com/api/v1',
      tenantApiConfig: TenantApiConfig(schoolId: '4'),
      httpClient: client,
    );

    await expectLater(
      service.fetchCourses(_token()),
      throwsA(isA<FormatException>()),
    );
    client.close();
  });

  test('does not send tenant credentials to external material hosts', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'cdn.example.test');
      expect(request.headers.containsKey('Authorization'), isFalse);
      expect(request.headers.containsKey('X-School-ID'), isFalse);
      return http.Response.bytes([1, 2, 3], 200);
    });
    final service = ElearningService(
      baseUrl: 'https://api.example.com/api/v1',
      tenantApiConfig: TenantApiConfig(schoolId: '4'),
      httpClient: client,
    );

    final response = await service.downloadMaterial(
      _token(),
      Uri.parse('https://cdn.example.test/material.mp4'),
    );

    expect(await response.stream.toBytes(), [1, 2, 3]);
    client.close();
  });
}
