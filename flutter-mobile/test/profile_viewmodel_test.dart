import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/auth/models/auth_model.dart';
import 'package:flutter_application_1/features/profile/local/profile_local_storage.dart';
import 'package:flutter_application_1/features/profile/repositories/profile_repository.dart';
import 'package:flutter_application_1/features/profile/services/profile_service.dart';
import 'package:flutter_application_1/features/profile/viewmodel/profile_viewmodel.dart';
import 'package:flutter_application_1/services/tenant_api_config.dart';

class FakeProfileStorage extends ProfileLocalStorage {
  final Map<String, Map<String, dynamic>> profiles = {};
  int saveCount = 0;

  @override
  Future<Map<String, dynamic>?> loadProfile(String cacheKey) async =>
      profiles[cacheKey];

  @override
  Future<void> saveProfile(
    String cacheKey,
    Map<String, dynamic> profile,
  ) async {
    saveCount++;
    profiles[cacheKey] = profile;
  }
}

class FakeProfileService extends ProfileService {
  FakeProfileService()
    : super(
        baseUrl: 'https://example.com/api/v1',
        tenantApiConfig: TenantApiConfig(schoolId: '8'),
      );

  int requestCount = 0;
  bool failRequests = false;

  @override
  Future<Map<String, dynamic>> getMyProfile(String token) async {
    requestCount++;
    if (failRequests) throw Exception('offline');
    return {
      'id': 41,
      'user_id': 12,
      'partner_id': 27,
      'nama_lengkap': 'Siswa Contoh',
      'nis': 'NIS-12',
      'nisn': 'NISN-12',
      'kelas': 'Kelas 4',
      'rombel': 'A',
      'tempat_tanggal_lahir': 'Bogor',
      'usia': '10',
      'status_aktif': true,
    };
  }
}

UserProfile _user() => UserProfile(
  userId: 12,
  partnerId: 27,
  name: 'Nama Login',
  username: 'siswa12',
  email: 'siswa@example.com',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('coalesces refresh and refreshes cached profile in a new view model', () async {
    final storage = FakeProfileStorage();
    final service = FakeProfileService();
    final repository = ProfileRepository(
      apiService: service,
      localStorage: storage,
    );
    final viewModel = ProfileViewModel(repository: repository);

    await Future.wait([
      viewModel.loadProfileOnce(token: 'token', user: _user(), schoolId: '8'),
      viewModel.loadProfileOnce(token: 'token', user: _user(), schoolId: '8'),
    ]);
    await viewModel.loadProfileOnce(
      token: 'token',
      user: _user(),
      schoolId: '8',
    );

    expect(service.requestCount, 1);
    expect(storage.saveCount, 1);
    expect(viewModel.profile?.name, 'Siswa Contoh');

    final nextAppViewModel = ProfileViewModel(
      repository: ProfileRepository(apiService: service, localStorage: storage),
    );
    await nextAppViewModel.loadProfileOnce(
      token: 'token',
      user: _user(),
      schoolId: '8',
    );

    expect(service.requestCount, 2);
    expect(storage.saveCount, 2);
    expect(nextAppViewModel.profile?.nis, 'NIS-12');
  });

  test('profile cache key is scoped to school and user', () async {
    final storage = FakeProfileStorage();
    final service = FakeProfileService();
    final viewModel = ProfileViewModel(
      repository: ProfileRepository(apiService: service, localStorage: storage),
    );

    await viewModel.loadProfileOnce(
      token: 'token',
      user: _user(),
      schoolId: '8',
    );
    await viewModel.loadProfileOnce(
      token: 'token',
      user: _user(),
      schoolId: '9',
    );

    expect(service.requestCount, 2);
    expect(storage.profiles.keys, containsAll(['8:12', '9:12']));
  });

  test(
    'cached profile remains available and reports failed refresh offline',
    () async {
      final storage = FakeProfileStorage()
        ..profiles['8:12'] = {
          'id': 41,
          'user_id': 12,
          'partner_id': 27,
          'foto_siswa': '',
          'nama_lengkap': 'Profil Lokal',
          'nis': 'NIS-12',
          'nisn': 'NISN-12',
          'kelas': 'Kelas 4',
          'rombel': 'A',
          'tempat_tanggal_lahir': 'Bogor',
          'usia': '10',
          'status_aktif': true,
        };
      final service = FakeProfileService()..failRequests = true;
      final viewModel = ProfileViewModel(
        repository: ProfileRepository(
          apiService: service,
          localStorage: storage,
        ),
      );

      await viewModel.loadProfileOnce(
        token: 'token',
        user: _user(),
        schoolId: '8',
      );

      expect(service.requestCount, 1);
      expect(viewModel.profile?.name, 'Profil Lokal');
      expect(viewModel.errorMessage, contains('menampilkan cache lokal'));
    },
  );
}
