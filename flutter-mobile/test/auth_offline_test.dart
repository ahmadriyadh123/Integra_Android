import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/auth/local/auth_local_storage.dart';
import 'package:flutter_application_1/features/auth/models/auth_model.dart';
import 'package:flutter_application_1/features/auth/repositories/auth_repository.dart';
import 'package:flutter_application_1/features/auth/services/auth_service.dart';
import 'package:flutter_application_1/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:flutter_application_1/features/profile/viewmodel/profile_viewmodel.dart';
import 'package:flutter_application_1/features/kurikulum/buku-komunikasi/local/buku_komunikasi_local_storage.dart';
import 'package:flutter_application_1/features/kurikulum/buku-komunikasi/repositories/buku_komunikasi_repository.dart';
import 'package:flutter_application_1/features/kurikulum/buku-komunikasi/services/buku_komunikasi_service.dart';
import 'package:flutter_application_1/services/tenant_api_config.dart';

class FakeAuthService extends AuthService {
  FakeAuthService()
    : super(
        baseUrl: 'https://example.com',
        tenantApiConfig: TenantApiConfig(schoolId: '1'),
      );

  @override
  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    throw const FormatException('offline');
  }
}

class FakeLocalStorage extends AuthLocalStorage {
  String? savedPassword;
  String? lastUpdatedCurrentPassword;
  String? lastUpdatedNewPassword;

  @override
  Future<void> updateSavedPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    lastUpdatedCurrentPassword = currentPassword;
    lastUpdatedNewPassword = newPassword;
    savedPassword = newPassword;
  }

  @override
  Future<String> loadPassword() async => savedPassword ?? '';
}

class FakeBukuKomunikasiStorage extends BukuKomunikasiLocalStorage {
  final List<Map<String, dynamic>> pendingNotes = [];

  @override
  Future<void> savePendingNote({
    required int lineId,
    required String day,
    required String noteText,
    String? month,
    int? week,
  }) async {
    pendingNotes.add({
      'line_id': lineId,
      'day': day,
      'note_text': noteText,
      'month': month,
      'week': week,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> loadPendingNotes() async =>
      List.from(pendingNotes);
}

class FakeBukuKomunikasiService extends BukuKomunikasiService {
  FakeBukuKomunikasiService()
    : super(
        baseUrl: 'https://example.com',
        tenantApiConfig: TenantApiConfig(schoolId: '1'),
      );

  @override
  Future<bool> submitDailyNote({
    required String token,
    required int lineId,
    required String day,
    required String noteText,
    String? month,
    int? week,
  }) async {
    throw const SocketException('offline');
  }
}

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
  Future<void> saveAuth(
    Map<String, dynamic> data, {
    required String username,
    required String password,
  }) async {
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
  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {}

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

    test(
      'restoreSessionFromHive loads auth from local storage without API call',
      () async {
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
          },
        };

        final result = await viewModel.restoreSessionFromHive();

        expect(result, true);
        expect(fakeRepository.loginCalled, false);
        expect(viewModel.token, 'header.eyJleHAiOjI1MjQ2MDgwMDB9.signature');
        expect(viewModel.user?.username, 'testuser');
      },
    );

    test(
      'restoreSessionFromHive returns false if no saved auth in Hive',
      () async {
        fakeRepository.mockAuthData = null;

        final result = await viewModel.restoreSessionFromHive();

        expect(result, false);
        expect(fakeRepository.loginCalled, false);
      },
    );

    test('login stores full auth result to Hive for offline restore', () async {
      fakeRepository.mockLoginResult = AuthResult(
        accessToken: 'new_token_456',
        tokenType: 'bearer',
        user: UserProfile(
          userId: 2,
          partnerId: 3,
          studentId: 4,
          nis: '54321',
          nisn: '9876543210',
          name: 'New User',
          username: 'newuser',
          email: 'new@example.com',
          className: 'Kelas 4',
          rombel: 'A',
          tempatTanggalLahir: 'Bandung, 1 Januari 2015',
          usia: '11 tahun',
          isPortal: false,
        ),
      );

      final result = await viewModel.login('newuser', 'password123');

      expect(result, true);
      expect(fakeRepository.saveAuthCalled, true);
      expect(viewModel.token, 'new_token_456');
      expect(fakeRepository.mockAuthData!['user']['nisn'], '9876543210');
      expect(fakeRepository.mockAuthData!['user']['rombel'], 'A');
      expect(
        fakeRepository.mockAuthData!['user']['tempat_tanggal_lahir'],
        'Bandung, 1 Januari 2015',
      );
    });

    test('profile is built from the locally available user data', () {
      final profileViewModel = ProfileViewModel();
      final user = UserProfile(
        userId: 2,
        partnerId: 3,
        studentId: 4,
        name: 'New User',
        username: 'newuser',
        email: 'new@example.com',
        nis: '54321',
        nisn: '9876543210',
        className: 'Kelas 4',
        rombel: 'A',
        tempatTanggalLahir: 'Bandung, 1 Januari 2015',
        usia: '11 tahun',
      );

      profileViewModel.setProfile(user);

      expect(profileViewModel.profile?.name, 'New User');
      expect(profileViewModel.profile?.nisn, '9876543210');
      expect(profileViewModel.profile?.rombel, 'A');
      expect(profileViewModel.profile?.photoUrl, isEmpty);
    });

    test(
      'changePassword falls back to local storage when network is unavailable',
      () async {
        final fakeService = FakeAuthService();
        final fakeStorage = FakeLocalStorage();
        fakeStorage.savedPassword = 'old-password';

        final repository = AuthRepository(
          apiService: fakeService,
          localStorageService: fakeStorage,
        );

        await repository.changePassword(
          token: 'token',
          currentPassword: 'old-password',
          newPassword: 'new-password-123',
        );

        expect(fakeStorage.lastUpdatedCurrentPassword, 'old-password');
        expect(fakeStorage.lastUpdatedNewPassword, 'new-password-123');
        expect(fakeStorage.savedPassword, 'new-password-123');
      },
    );

    test('buku komunikasi saves pending note locally when offline', () async {
      final storage = FakeBukuKomunikasiStorage();
      final service = FakeBukuKomunikasiService();
      final repository = BukuKomunikasiRepository(
        apiService: service,
        localStorage: storage,
      );

      final result = await repository.submitDailyNote(
        token: 'token',
        lineId: 12,
        day: 'senin',
        noteText: 'Saya hadir tepat waktu',
        month: 'Januari',
        week: 1,
      );

      expect(result, true);
      expect(storage.pendingNotes.length, 1);
      expect(storage.pendingNotes.first['note_text'], 'Saya hadir tepat waktu');
    });
  });
}
