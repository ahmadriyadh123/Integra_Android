import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/features/auth/services/auth_service.dart';
import 'package:flutter_application_1/services/tenant_api_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'fetches schools once and uses the locally cached list afterwards',
    () async {
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
    },
  );
}
