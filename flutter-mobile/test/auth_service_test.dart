import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/features/auth/services/auth_service.dart';
import 'package:flutter_application_1/services/tenant_api_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uses cached schools until a refresh is explicitly requested', () async {
    SharedPreferences.setMockInitialValues({});
    var requestCount = 0;
    final service = AuthService(
      baseUrl: 'https://example.com/api/v1',
      tenantApiConfig: TenantApiConfig(),
      client: MockClient((request) async {
        requestCount++;
        expect(request.url.path, '/api/v1/auth/schools');
        return http.Response('''
          {
            "success": true,
            "data": [
              {"id": 7, "nama_sekolah": "Sekolah A"}
            ]
          }
          ''', 200);
      }),
    );

    final firstResult = await service.fetchSchools();
    final secondResult = await service.fetchSchools();

    expect(requestCount, 1);
    expect(firstResult.map((school) => school.name), ['Sekolah A']);
    expect(secondResult.map((school) => school.id), ['7']);
  });

  test(
    'force refresh fetches and replaces the locally cached school list',
    () async {
      SharedPreferences.setMockInitialValues({});
      var requestCount = 0;
      final service = AuthService(
        baseUrl: 'https://example.com/api/v1',
        tenantApiConfig: TenantApiConfig(),
        client: MockClient((request) async {
          requestCount++;
          final schoolName = requestCount == 1
              ? 'Sekolah Lama'
              : 'Sekolah Baru';
          return http.Response(
            '{"success":true,"data":[{"id":7,"nama_sekolah":"$schoolName"}]}',
            200,
          );
        }),
      );

      final initial = await service.fetchSchools();
      final refreshed = await service.fetchSchools(forceRefresh: true);
      final cached = await service.fetchSchools();

      expect(requestCount, 2);
      expect(initial.single.name, 'Sekolah Lama');
      expect(refreshed.single.name, 'Sekolah Baru');
      expect(cached.single.name, 'Sekolah Baru');
    },
  );

  test('retains the cached schools when a forced refresh fails', () async {
    SharedPreferences.setMockInitialValues({});
    final service = AuthService(
      baseUrl: 'https://example.com/api/v1',
      tenantApiConfig: TenantApiConfig(),
      client: MockClient((request) async {
        return http.Response(
          '{"success":true,"data":[{"id":7,"nama_sekolah":"Sekolah A"}]}',
          200,
        );
      }),
    );
    await service.fetchSchools();

    final offlineService = AuthService(
      baseUrl: 'https://example.com/api/v1',
      tenantApiConfig: TenantApiConfig(),
      client: MockClient((request) async => http.Response('Server error', 503)),
    );

    await expectLater(
      offlineService.fetchSchools(forceRefresh: true),
      throwsException,
    );
    final cached = await offlineService.fetchSchools();

    expect(cached.single.name, 'Sekolah A');
  });

  test('login sends the currently selected school id', () async {
    SharedPreferences.setMockInitialValues({});
    final service = AuthService(
      baseUrl: 'https://example.com/api/v1',
      tenantApiConfig: TenantApiConfig(schoolId: '8'),
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/login');
        expect(request.headers['X-School-ID'], '8');
        return http.Response(
          '{"success":true,"data":{"access_token":"token","token_type":"bearer"}}',
          200,
        );
      }),
    );

    final result = await service.login('siswa', 'password');

    expect(result['access_token'], 'token');
  });
}
