import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/data/local/auth/auth_local_storage.dart';
import 'package:flutter_application_1/data/model/auth/auth_model.dart';
import 'package:flutter_application_1/data/repositories/auth/auth_repository.dart';
import 'package:flutter_application_1/data/services/auth/auth_service.dart';
import 'package:flutter_application_1/ui/auth/view_models/auth_viewmodel.dart';
import 'package:flutter_application_1/ui/profile/view_models/profile_viewmodel.dart';
import 'package:flutter_application_1/data/local/kurikulum/buku-komunikasi/buku_komunikasi_local_storage.dart';
import 'package:flutter_application_1/data/model/kurikulum/buku-komunikasi/buku_komunikasi_model.dart';
import 'package:flutter_application_1/data/repositories/kurikulum/buku-komunikasi/buku_komunikasi_repository.dart';
import 'package:flutter_application_1/data/services/kurikulum/buku-komunikasi/buku_komunikasi_service.dart';
import 'package:flutter_application_1/config/api/tenant_api_config.dart';

class FakeAuthService extends AuthService {
  FakeAuthService({this.offline = true})
    : super(
        baseUrl: 'https://example.com',
        tenantApiConfig: TenantApiConfig(schoolId: '1'),
      );

  bool offline;

  @override
  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (offline) throw const AuthNetworkException('offline');
  }
}

class FakeLocalStorage extends AuthLocalStorage {
  String? savedPassword;
  String savedUsername = '';
  Map<String, dynamic>? savedAuthData;
  PendingPasswordChange? pendingPasswordChange;

  @override
  Future<String> loadPassword() async => savedPassword ?? '';

  @override
  Future<String> loadUsername() async => savedUsername;

  @override
  Future<Map<String, dynamic>?> loadAuth() async => savedAuthData;

  @override
  Future<Map<String, dynamic>?> loadOfflineAuth() async => savedAuthData;

  @override
  Future<PendingPasswordChange?> loadPendingPasswordChange() async =>
      pendingPasswordChange;

  @override
  Future<void> queuePasswordChange({
    required String currentPassword,
    required String newPassword,
  }) async {
    pendingPasswordChange = PendingPasswordChange(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> completePasswordChange(String newPassword) async {
    savedPassword = newPassword;
    pendingPasswordChange = null;
  }

  @override
  Future<void> saveAuth(
    Map<String, dynamic> authData, {
    required String username,
    required String password,
  }) async {
    savedAuthData = authData;
    savedUsername = username;
    savedPassword = password;
  }

  @override
  Future<void> cancelPendingPasswordChange() async {
    pendingPasswordChange = null;
  }
}

class FakeBukuKomunikasiStorage extends BukuKomunikasiLocalStorage {
  final List<Map<String, dynamic>> pendingNotes = [];

  @override
  Future<void> clearCache({required String scope}) async {}

  @override
  Future<void> savePendingNote({
    required int lineId,
    required String day,
    required String noteText,
    String? month,
    int? week,
    required String scope,
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
  Future<List<Map<String, dynamic>>> loadPendingNotes({
    required String scope,
  }) async => List.from(pendingNotes);
}

class FakeBukuKomunikasiService extends BukuKomunikasiService {
  FakeBukuKomunikasiService()
    : super(
        baseUrl: 'https://example.com',
        tenantApiConfig: TenantApiConfig(schoolId: '1'),
      );

  bool offline = true;

  @override
  Future<bool> submitDailyNote({
    required String token,
    required int lineId,
    required String day,
    required String noteText,
    String? month,
    int? week,
  }) async {
    if (offline) throw const SocketException('offline');
    return true;
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
  bool clearStoredTokensCalled = false;
  bool invalidateCachedSession = false;
  bool tokenMatchesSelectedSchool = true;

  @override
  Future<AuthResult> login(String username, String password) async {
    loginCalled = true;
    if (mockLoginException != null) throw mockLoginException!;
    if (mockLoginResult != null) return mockLoginResult!;
    throw Exception('Login error');
  }

  AuthResult? mockOfflineLoginResult;
  String savedUsername = '';
  String savedPassword = '';
  bool resolvePendingPasswordChangeCalled = false;
  bool refreshSessionCalled = false;
  AuthResult? mockRefreshResult;

  @override
  Future<AuthResult> refreshSession(AuthResult currentSession) async {
    refreshSessionCalled = true;
    if (currentSession.refreshToken == null) {
      throw const AuthSessionInvalidException('Refresh token tidak tersedia');
    }
    return mockRefreshResult ?? currentSession;
  }

  @override
  Future<void> revokeRefreshToken(String? refreshToken) async {}

  @override
  Future<AuthResult?> loginOffline(String username, String password) async {
    if (username == savedUsername && password == savedPassword) {
      return mockOfflineLoginResult;
    }
    return null;
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
  Future<Map<String, dynamic>?> loadOfflineAuth() async => mockAuthData;

  @override
  Future<void> clearAuth() async {
    clearAuthCalled = true;
    mockAuthData = null;
  }

  @override
  Future<void> clearSession() async {
    mockAuthData = null;
  }

  @override
  Future<void> clearStoredTokens() async {
    clearStoredTokensCalled = true;
    mockAuthData = null;
  }

  @override
  Future<void> validateSession(String token) async {
    if (invalidateCachedSession) {
      throw const AuthSessionInvalidException('Signature verification failed');
    }
  }

  @override
  bool isTokenForSelectedSchool(String token) => tokenMatchesSelectedSchool;

  @override
  Future<PasswordChangeStatus> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async => PasswordChangeStatus.completed;

  @override
  Future<bool> syncPendingPasswordChange(String token) async => false;

  @override
  Future<bool> hasPendingPasswordChange() async => false;

  @override
  Future<bool> resolvePendingPasswordChangeAfterLogin(
    String authenticatedPassword,
  ) async {
    resolvePendingPasswordChangeCalled = true;
    return false;
  }

  @override
  Future<void> cancelPendingPasswordChange() async {}

  @override
  Future<int> getLastTabIndex() async => 0;

  @override
  Future<void> setLastTabIndex(int index) async {}

  @override
  Future<String> loadUsername() async => 'testuser';

  @override
  Future<String> loadPassword() async =>
      savedPassword.isEmpty ? 'password123' : savedPassword;
}

void main() {
  group('Offline-First Login Tests', () {
    late FakeAuthRepository fakeRepository;
    late AuthViewModel viewModel;

    setUp(() {
      fakeRepository = FakeAuthRepository();
      viewModel = AuthViewModel(repository: fakeRepository);
    });

    test('restoreSessionFromHive keeps a valid cached session', () async {
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
    });

    test(
      'refreshes an expired cached token when refresh token is available',
      () async {
        fakeRepository.mockAuthData = {
          'access_token': 'header.eyJleHAiOjF9.signature',
          'refresh_token': 'old-refresh',
          'token_type': 'bearer',
          'user': {
            'user_id': 1,
            'name': 'Test User',
            'username': 'testuser',
            'email': 'test@example.com',
          },
        };
        fakeRepository.mockRefreshResult = AuthResult(
          accessToken: 'fresh-access-token',
          refreshToken: 'rotated-refresh-token',
          tokenType: 'bearer',
          user: UserProfile(
            userId: 1,
            name: 'Test User',
            username: 'testuser',
            email: 'test@example.com',
          ),
        );

        final result = await viewModel.restoreSessionFromHive();

        expect(result, true);
        expect(fakeRepository.refreshSessionCalled, true);
        expect(viewModel.token, 'fresh-access-token');
      },
    );

    test('parses auth when cached user map has dynamic key types', () {
      final result = AuthResult.fromJson({
        'access_token': 'cached-token',
        'token_type': 'bearer',
        'user': <dynamic, dynamic>{
          'user_id': 1,
          'name': 'Cached User',
          'username': 'cached-user',
          'email': 'cached@example.com',
        },
      });

      expect(result.user.name, 'Cached User');
      expect(result.user.username, 'cached-user');
    });

    test(
      'restoreSessionFromHive returns false if no saved auth in Hive',
      () async {
        fakeRepository.mockAuthData = null;

        final result = await viewModel.restoreSessionFromHive();

        expect(result, false);
        expect(fakeRepository.loginCalled, false);
      },
    );

    test('restoreSessionFromHive clears a token for another school', () async {
      fakeRepository.tokenMatchesSelectedSchool = false;
      fakeRepository.mockAuthData = {
        'access_token': 'token-from-another-school',
        'token_type': 'bearer',
        'user': {
          'user_id': 1,
          'name': 'Test User',
          'username': 'testuser',
          'email': 'test@example.com',
        },
      };

      final result = await viewModel.restoreSessionFromHive();

      expect(result, false);
      expect(fakeRepository.clearAuthCalled, true);
      expect(viewModel.isLoggedIn, false);
    });

    test('restore clears a cached token rejected by the server', () async {
      fakeRepository.invalidateCachedSession = true;
      fakeRepository.mockAuthData = {
        'access_token': 'header.eyJleHAiOjI1MjQ2MDgwMDB9.signature',
        'token_type': 'bearer',
        'user': {
          'user_id': 1,
          'name': 'Test User',
          'username': 'testuser',
          'email': 'test@example.com',
        },
      };

      final result = await viewModel.restoreSessionFromHive();

      expect(result, false);
      expect(fakeRepository.clearStoredTokensCalled, true);
      expect(viewModel.isLoggedIn, false);
      expect(viewModel.errorMessage, 'Signature verification failed');
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

    test(
      'repository uses only the saved credentials for offline login',
      () async {
        final token = 'eyJhbGciOiJIUzI1NiJ9.eyJzY2hvb2xfaWQiOjF9.c2ln';
        final storage = FakeLocalStorage()
          ..savedUsername = 'saved-user'
          ..savedPassword = 'saved-password'
          ..savedAuthData = {
            'access_token': token,
            'token_type': 'bearer',
            'user': {
              'user_id': 7,
              'name': 'Saved User',
              'username': 'saved-user',
              'email': 'saved@example.com',
            },
          };
        final repository = AuthRepository(
          apiService: FakeAuthService(),
          localStorageService: storage,
        );

        final offlineResult = await repository.loginOffline(
          'saved-user',
          'saved-password',
        );
        final wrongPasswordResult = await repository.loginOffline(
          'saved-user',
          'incorrect',
        );

        expect(offlineResult?.user.username, 'saved-user');
        expect(wrongPasswordResult, isNull);
      },
    );

    test(
      'login falls back to saved credentials when the server is offline',
      () async {
        final offlineUser = UserProfile(
          userId: 7,
          name: 'Saved User',
          username: 'saved-user',
          email: 'saved@example.com',
        );
        fakeRepository.mockLoginException = const AuthNetworkException(
          'offline',
        );
        fakeRepository.savedUsername = 'saved-user';
        fakeRepository.savedPassword = 'saved-password';
        fakeRepository.mockOfflineLoginResult = AuthResult(
          accessToken: 'cached-token',
          tokenType: 'bearer',
          user: offlineUser,
        );

        final result = await viewModel.login('saved-user', 'saved-password');

        expect(result, isTrue);
        expect(viewModel.isLoggedIn, isTrue);
        expect(viewModel.token, 'cached-token');
        expect(viewModel.user?.username, 'saved-user');
        expect(fakeRepository.saveAuthCalled, isTrue);
        expect(fakeRepository.resolvePendingPasswordChangeCalled, isFalse);
      },
    );

    test('offline login rejects credentials not previously saved', () async {
      fakeRepository.mockLoginException = const AuthNetworkException('offline');
      fakeRepository.savedUsername = 'saved-user';
      fakeRepository.savedPassword = 'saved-password';

      final result = await viewModel.login('saved-user', 'wrong-password');

      expect(result, isFalse);
      expect(viewModel.isLoggedIn, isFalse);
      expect(viewModel.errorMessage, contains('Login offline'));
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
      'changePassword queues securely when offline without changing saved password',
      () async {
        final fakeService = FakeAuthService();
        final fakeStorage = FakeLocalStorage();
        fakeStorage.savedPassword = 'old-password';

        final repository = AuthRepository(
          apiService: fakeService,
          localStorageService: fakeStorage,
        );

        final result = await repository.changePassword(
          token: 'token',
          currentPassword: 'old-password',
          newPassword: 'new-password-123',
        );

        expect(result, PasswordChangeStatus.queued);
        expect(fakeStorage.savedPassword, 'old-password');
        expect(
          fakeStorage.pendingPasswordChange?.newPassword,
          'new-password-123',
        );
      },
    );

    test(
      'syncPendingPasswordChange completes queue after server confirmation',
      () async {
        final fakeService = FakeAuthService();
        final fakeStorage = FakeLocalStorage()..savedPassword = 'old-password';
        final repository = AuthRepository(
          apiService: fakeService,
          localStorageService: fakeStorage,
        );

        await repository.changePassword(
          token: 'token',
          currentPassword: 'old-password',
          newPassword: 'new-password-123',
        );
        fakeService.offline = false;

        expect(await repository.syncPendingPasswordChange('token'), isTrue);
        expect(fakeStorage.savedPassword, 'new-password-123');
        expect(fakeStorage.pendingPasswordChange, isNull);
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
        token: 'header.eyJzY2hvb2xfaWQiOjEsInVpZCI6Mn0.signature',
        lineId: 12,
        day: 'senin',
        noteText: 'Saya hadir tepat waktu',
        month: 'Januari',
        week: 1,
      );

      expect(result, BukuKomunikasiSubmitStatus.queued);
      expect(storage.pendingNotes.length, 1);
      expect(storage.pendingNotes.first['note_text'], 'Saya hadir tepat waktu');
    });

    test('buku komunikasi reports server-confirmed note separately', () async {
      final storage = FakeBukuKomunikasiStorage();
      final service = FakeBukuKomunikasiService()..offline = false;
      final repository = BukuKomunikasiRepository(
        apiService: service,
        localStorage: storage,
      );

      final result = await repository.submitDailyNote(
        token: 'header.eyJzY2hvb2xfaWQiOjEsInVpZCI6Mn0.signature',
        lineId: 12,
        day: 'senin',
        noteText: 'Catatan tersimpan',
      );

      expect(result, BukuKomunikasiSubmitStatus.submitted);
      expect(storage.pendingNotes, isEmpty);
    });
  });
}
