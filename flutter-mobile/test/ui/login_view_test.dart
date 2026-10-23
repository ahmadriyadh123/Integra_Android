import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/data/local/auth/auth_local_storage.dart';
import 'package:flutter_application_1/data/model/auth/school_model.dart';
import 'package:flutter_application_1/data/repositories/auth/auth_repository.dart';
import 'package:flutter_application_1/data/services/auth/auth_service.dart';
import 'package:flutter_application_1/ui/auth/widgets/login_screen.dart';
import 'package:flutter_application_1/ui/auth/view_models/auth_viewmodel.dart';
import 'package:flutter_application_1/config/api/tenant_api_config.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(baseUrl: '', tenantApiConfig: TenantApiConfig());

  @override
  Future<List<SchoolOption>?> loadCachedSchools() async => null;

  @override
  Future<List<SchoolOption>> fetchSchools({bool forceRefresh = false}) async =>
      const [SchoolOption(id: '1', name: 'Sekolah Contoh')];
}

class _OfflineAuthService extends _FakeAuthService {
  @override
  Future<List<SchoolOption>?> loadCachedSchools() async => const [
    SchoolOption(id: '1', name: 'Sekolah Tersimpan'),
  ];

  @override
  Future<List<SchoolOption>> fetchSchools({bool forceRefresh = false}) async {
    throw Exception('Gagal terhubung ke server: connection failed');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('school dropdown works without a school-save callback', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final authService = _FakeAuthService();
    final authViewModel = AuthViewModel(
      repository: AuthRepository(
        apiService: authService,
        localStorageService: AuthLocalStorage(),
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthService>.value(value: authService),
          ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
          Provider<TenantApiConfig>.value(value: TenantApiConfig()),
        ],
        child: const MaterialApp(home: LoginView()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pilih sekolah'));
    await tester.pumpAndSettle();

    expect(find.text('Sekolah Contoh'), findsOneWidget);
  });

  testWidgets('cached schools do not show a warning and login remains available', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final authService = _OfflineAuthService();
    final authViewModel = AuthViewModel(
      repository: AuthRepository(
        apiService: authService,
        localStorageService: AuthLocalStorage(),
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthService>.value(value: authService),
          ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
          Provider<TenantApiConfig>.value(value: TenantApiConfig()),
        ],
        child: const MaterialApp(home: LoginView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.textContaining('Gagal memperbarui daftar.'), findsNothing);
  });
}
