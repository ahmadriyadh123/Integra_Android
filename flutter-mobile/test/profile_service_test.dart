import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_application_1/features/profile/services/profile_service.dart';
import 'package:flutter_application_1/services/tenant_api_config.dart';

void main() {
  test('fetches a profile image once for concurrent and later calls', () async {
    var requestCount = 0;
    final payload = base64Url
        .encode(utf8.encode(jsonEncode({'school_id': 123})))
        .replaceAll('=', '');
    final token = 'header.$payload.signature';
    final service = ProfileService(
      baseUrl: 'https://example.com/api/v1',
      tenantApiConfig: TenantApiConfig(schoolId: '123'),
      client: MockClient((request) async {
        requestCount++;
        expect(request.headers['X-School-ID'], '123');
        return http.Response('image-bytes', 200);
      }),
    );

    final images = await Future.wait([
      service.getProfileImage(token, 275),
      service.getProfileImage(token, 275),
    ]);
    final laterImage = await service.getProfileImage(token, 275);

    expect(requestCount, 1);
    expect(images[0], images[1]);
    expect(laterImage, images[0]);
  });
}
