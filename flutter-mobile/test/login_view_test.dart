import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/features/auth/local/auth_local_storage.dart';
import 'package:flutter_application_1/features/auth/models/school_model.dart';
import 'package:flutter_application_1/features/auth/repositories/auth_repository.dart';
import 'package:flutter_application_1/features/auth/services/auth_service.dart';
import 'package:flutter_application_1/features/auth/view/login_view.dart';
import 'package:flutter_application_1/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:flutter_application_1/services/tenant_api_config.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(baseUrl: '', tenantApiConfig: TenantApiConfig());

  @override
  Future<List<SchoolOption>?> loadCachedSchools() async => null;

  @override
  Future<List<SchoolOption>> fetchSchools({bool forceRefresh = false}) async =>
      const [SchoolOption(id: '1', name: 'Sekolah Contoh')];
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
}
