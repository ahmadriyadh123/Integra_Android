import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/auth/local/auth_local_storage.dart';
import 'package:flutter_application_1/features/auth/models/auth_model.dart';
import 'package:flutter_application_1/features/auth/repositories/auth_repository.dart';
import 'package:flutter_application_1/features/auth/services/auth_service.dart';
import 'package:flutter_application_1/features/auth/viewmodel/auth_viewmodel.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  AuthService get apiService => throw UnimplementedError();

  @override
  AuthLocalStorage get localStorageService => throw UnimplementedError();

  AuthResult? mockLoginResult;
  Exception? mockLoginException;
  bool loginCalled = false;

  Map<String, dynamic>? mockAuthData;
  bool saveAuthCalled = false;
  bool clearAuthCalled = false;

  @override
  Future<AuthResult> login(String username, String password) async {
    loginCalled = true;
    if (mockLoginException != null) throw mockLoginException!;
    if (mockLoginResult != null) return mockLoginResult!;
    throw Exception('Login error');
  }

  @override
  Future<void> saveAuth(Map<String, dynamic> data, {required String username, required String password}) async {
    saveAuthCalled = true;
    mockAuthData = data;
  }

  @override
  Future<Map<String, dynamic>?> loadAuth() async {
    return mockAuthData;
  }

  @override
  Future<void> clearAuth() async {
    clearAuthCalled = true;
    mockAuthData = null;
  }

  @override
  Future<void> validateSession(String token) async {}

  @override
  Future<void> changePassword({required String token, required String currentPassword, required String newPassword}) async {}

  @override
  Future<int> getLastTabIndex() async => 0;

  @override
  Future<void> setLastTabIndex(int index) async {}

  @override
  Future<String> loadUsername() async => 'testuser';

  @override
  Future<String> loadPassword() async => 'password123';
}

void main() {
  group('Offline-First Login Tests', () {
    late FakeAuthRepository fakeRepository;
    late AuthViewModel viewModel;

    setUp(() {
      fakeRepository = FakeAuthRepository();
      viewModel = AuthViewModel(repository: fakeRepository);
    });

    test('restoreSessionFromHive loads auth from local storage without API call', () async {
      fakeRepository.mockAuthData = {
        'access_token': 'header.eyJleHAiOjI1MjQ2MDgwMDB9.signature',
        'token_type': 'bearer',
        'user': {
          'user_id': 1,
          'partner_id': 2,
          'student_id': 3,
          'nis': '12345',
          'name': 'Test User',
          'username': 'testuser',
          'email': 'test@example.com',
          'is_portal': false,
        }
      };

      final result = await viewModel.restoreSessionFromHive();

      expect(result, true);
      expect(fakeRepository.loginCalled, false);
      expect(viewModel.token, 'header.eyJleHAiOjI1MjQ2MDgwMDB9.signature');
      expect(viewModel.user?.username, 'testuser');
    });

    test('restoreSessionFromHive returns false if no saved auth in Hive', () async {
      fakeRepository.mockAuthData = null;

      final result = await viewModel.restoreSessionFromHive();

      expect(result, false);
      expect(fakeRepository.loginCalled, false);
    });

    test('login stores full auth result to Hive for offline restore', () async {
      fakeRepository.mockLoginResult = AuthResult(
        accessToken: 'new_token_456',
        tokenType: 'bearer',
        user: UserProfile(
          userId: 2,
          partnerId: 3,
          studentId: 4,
          nis: '54321',
          name: 'New User',
          username: 'newuser',
          email: 'new@example.com',
          isPortal: false,
        ),
      );

      final result = await viewModel.login('newuser', 'password123');

      expect(result, true);
      expect(fakeRepository.saveAuthCalled, true);
      expect(viewModel.token, 'new_token_456');
    });
  });
}
