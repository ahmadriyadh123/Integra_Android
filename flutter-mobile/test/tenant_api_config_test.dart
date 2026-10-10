import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/tenant_api_config.dart';

String _token(int schoolId) {
  final header = base64Url
      .encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})))
      .replaceAll('=', '');
  final payload = base64Url
      .encode(utf8.encode(jsonEncode({'school_id': schoolId})))
      .replaceAll('=', '');
  return '$header.$payload.c2ln';
}

void main() {
  test('accepts a token issued for the selected school', () {
    final config = TenantApiConfig(schoolId: '7');

    expect(config.tokenMatchesSelectedSchool(_token(7)), isTrue);
    expect(config.headers(token: _token(7))['X-School-ID'], '7');
    expect(
      config.headers(token: _token(7))['Authorization'],
      'Bearer ${_token(7)}',
    );
  });

  test('rejects a token issued for a different selected school', () {
    final config = TenantApiConfig(schoolId: '8');

    expect(config.tokenMatchesSelectedSchool(_token(7)), isFalse);
    expect(
      () => config.headers(token: _token(7)),
      throwsA(isA<TenantTokenMismatchException>()),
    );
  });

  test('rejects a token without a valid school claim', () {
    final config = TenantApiConfig(schoolId: '7');

    expect(config.tokenMatchesSelectedSchool('invalid-token'), isFalse);
    expect(
      () => config.headers(token: 'invalid-token'),
      throwsA(isA<TenantTokenMismatchException>()),
    );
  });

  test('rejects a server token with a string school claim', () {
    final config = TenantApiConfig(schoolId: '7');
    final header = base64Url
        .encode(utf8.encode(jsonEncode({'alg': 'HS256'})))
        .replaceAll('=', '');
    final payload = base64Url
        .encode(utf8.encode(jsonEncode({'school_id': '7'})))
        .replaceAll('=', '');

    expect(config.tokenMatchesSelectedSchool('$header.$payload.c2ln'), isFalse);
  });

  test('rejects unsigned or malformed JWTs', () {
    final config = TenantApiConfig(schoolId: '7');

    expect(
      config.tokenMatchesSelectedSchool(
        '${base64Url.encode(utf8.encode('{"alg":"none"}'))}.'
        '${base64Url.encode(utf8.encode('{"school_id":7}'))}.c2ln',
      ),
      isFalse,
    );
  });
}
