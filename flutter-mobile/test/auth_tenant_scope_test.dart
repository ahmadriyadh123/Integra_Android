import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/features/auth/local/auth_local_storage.dart';
import 'package:flutter_application_1/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:flutter_application_1/features/auth/repositories/auth_repository.dart';
import 'package:flutter_application_1/features/auth/services/auth_service.dart';
import 'package:flutter_application_1/services/tenant_api_config.dart';

class _TrackingAuthLocalStorage extends AuthLocalStorage {
  bool cleared = false;

  @override
  Future<void> clearAuth() async {
    cleared = true;
  }
}

String _token(int schoolId) {
  final header = base64Url
      .encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})))
      .replaceAll('=', '');
  final payload = base64Url
      .encode(utf8.encode(jsonEncode({'school_id': schoolId})))
      .replaceAll('=', '');
  return '$header.$payload.c2ln';
}

class _FakeAuthService extends AuthService {
  _FakeAuthService({
    required String schoolId,
    required this.responseToken,
    this.responseTokenType = 'bearer',
  })
    : super(
        baseUrl: 'https://example.com/api/v1',
        tenantApiConfig: TenantApiConfig(schoolId: schoolId),
      );

  final String responseToken;
  final String responseTokenType;

  @override
  Future<Map<String, dynamic>> login(String username, String password) async =>
      {
        'access_token': responseToken,
        'token_type': responseTokenType,
        'user': {
          'user_id': 17,
          'name': 'Siswa',
          'username': username,
          'email': 'siswa@example.com',
        },
      };
}

AuthRepository _repository({
  required String selectedSchoolId,
  required String responseToken,
  AuthLocalStorage? storage,
}) {
  final service = _FakeAuthService(
    schoolId: selectedSchoolId,
    responseToken: responseToken,
  );
  return AuthRepository(
    apiService: service,
    localStorageService: storage ?? AuthLocalStorage(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'login accepts an access token issued for the selected school',
    () async {
      final repository = _repository(
        selectedSchoolId: '7',
        responseToken: _token(7),
      );

      final result = await repository.login('siswa', 'password');

      expect(result.accessToken, _token(7));
    },
  );

  test('login rejects an access token issued for another school', () async {
    final repository = _repository(
      selectedSchoolId: '8',
      responseToken: _token(7),
    );

    await expectLater(
      repository.login('siswa', 'password'),
      throwsA(isA<FormatException>()),
    );
  });

  test('mismatched login token clears any stored session', () async {
    final storage = _TrackingAuthLocalStorage();
    final viewModel = AuthViewModel(
      repository: _repository(
        selectedSchoolId: '8',
        responseToken: _token(7),
        storage: storage,
      ),
    );

    expect(await viewModel.login('siswa', 'password'), isFalse);
    expect(viewModel.isLoggedIn, isFalse);
    expect(storage.cleared, isTrue);
    expect(
      viewModel.errorMessage,
      contains('tidak sesuai dengan sekolah yang dipilih'),
    );
  });

  test('login rejects a token response with a non-bearer token type', () async {
    final service = _FakeAuthService(
      schoolId: '7',
      responseToken: _token(7),
      responseTokenType: 'basic',
    );
    final repository = AuthRepository(
      apiService: service,
      localStorageService: AuthLocalStorage(),
    );

    await expectLater(
      repository.login('siswa', 'password'),
      throwsA(isA<TenantTokenMismatchException>()),
    );
  });
}
