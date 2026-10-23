import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/data/services/kurikulum/weekly_plan/weekly_plan_service.dart';
import 'package:flutter_application_1/config/api/tenant_api_config.dart';
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

WeeklyPlanService _service(MockClient client) => WeeklyPlanService(
  baseUrl: 'https://example.com/api/v1',
  tenantApiConfig: TenantApiConfig(schoolId: '4'),
  httpClient: client,
);

void main() {
  test(
    'server error detail is preserved instead of reported as a connection failure',
    () async {
      final service = _service(
        MockClient(
          (_) async => http.Response(
            jsonEncode({'detail': 'Database query failed'}),
            500,
          ),
        ),
      );

      await expectLater(
        service.fetchWeeklyPlanList(_token()),
        throwsA(
          predicate(
            (error) =>
                error.toString().contains('Database query failed') &&
                !error.toString().contains('Gagal terhubung'),
          ),
        ),
      );
    },
  );

  test('invalid server JSON remains a parsing error', () async {
    final service = _service(
      MockClient((_) async => http.Response('not-json', 200)),
    );

    await expectLater(
      service.fetchWeeklyPlanList(_token()),
      throwsA(isA<FormatException>()),
    );
  });

  test('transport failures are reported as connection failures', () async {
    final service = _service(
      MockClient((_) async => throw http.ClientException('offline')),
    );

    await expectLater(
      service.fetchWeeklyPlanList(_token()),
      throwsA(
        predicate(
          (error) =>
              error.toString().contains('Gagal terhubung ke server') &&
              error.toString().contains('offline'),
        ),
      ),
    );
  });
}
