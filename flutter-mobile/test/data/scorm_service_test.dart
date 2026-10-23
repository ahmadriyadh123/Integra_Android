import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/data/services/elearning/scorm_service.dart';
import 'package:flutter_application_1/config/api/tenant_api_config.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('surfaces Odoo authentication failure to the caller', () async {
    late Uri requestUri;
    final client = MockClient((request) async {
      requestUri = request.url;
      expect(request.method, 'POST');
      expect(request.url.path, '/web/session/authenticate');
      return http.Response(
        jsonEncode({
          'jsonrpc': '2.0',
          'error': {
            'message': 'Odoo Server Error',
            'data': {'message': 'Access denied'},
          },
        }),
        200,
      );
    });
    final service = ScormService(
      tenantApiConfig: TenantApiConfig(schoolId: '4'),
      httpClient: client,
    );

    await expectLater(
      service.authenticateOdooWebSession(
        targetUri: Uri.parse('https://odoo.example.com/content/package'),
        odooDb: 'school_db',
        odooUsername: 'student',
        odooPassword: 'secret',
      ),
      throwsA(
        isA<Exception>()
            .having(
              (error) => error.toString(),
              'message',
              contains('Autentikasi sesi Odoo gagal: Access denied'),
            )
            .having(
              (error) => error.toString(),
              'does not expose credentials',
              isNot(contains('secret')),
            ),
      ),
    );

    expect(requestUri.host, 'odoo.example.com');
    client.close();
  });

  test('rejects an Odoo response without a session id', () async {
    final client = MockClient(
      (_) async =>
          http.Response(jsonEncode({'jsonrpc': '2.0', 'result': {}}), 200),
    );
    final service = ScormService(
      tenantApiConfig: TenantApiConfig(schoolId: '4'),
      httpClient: client,
    );

    await expectLater(
      service.authenticateOdooWebSession(
        targetUri: Uri.parse('https://odoo.example.com/content/package'),
        odooDb: 'school_db',
        odooUsername: 'student',
        odooPassword: 'secret',
      ),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Autentikasi sesi Odoo gagal'),
        ),
      ),
    );
    client.close();
  });
}
