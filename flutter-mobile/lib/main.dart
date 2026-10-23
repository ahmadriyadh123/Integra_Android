import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_application_1/ui/auth/widgets/login_screen.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './config/providers/app_providers.dart';
import './data/local/auth/auth_local_storage.dart';
import './data/services/core/authenticated_http_client.dart';
import './config/api/remote_api_config_service.dart';
import './config/api/tenant_api_config.dart';

const _apiBaseUrlKey = 'api_base_url';
const _schoolIdKey = 'school_id';
const _defaultApiBaseUrl =
    'https://kp-sekolah.asetkoptii.com/mobile-api/api/v1';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final preferences = await SharedPreferences.getInstance();
  final configuredBaseUrl = getApiBaseUrl();
  var initialBaseUrl = configuredBaseUrl.isNotEmpty
      ? configuredBaseUrl
      : preferences.getString(_apiBaseUrlKey) ?? _defaultApiBaseUrl;
  if (configuredBaseUrl.isEmpty) {
    try {
      initialBaseUrl = await const RemoteApiConfigService().fetchBaseUrl();
      try {
        await preferences.setString(_apiBaseUrlKey, initialBaseUrl);
      } on PlatformException catch (error) {
        debugPrint('Gagal menyimpan konfigurasi API remote: $error');
      }
    } on RemoteApiConfigException catch (error) {
      debugPrint('Gagal memuat konfigurasi API remote: $error');
    } on TimeoutException {
      debugPrint('Permintaan konfigurasi API remote melewati batas waktu.');
    } on http.ClientException catch (error) {
      debugPrint('Gagal menghubungi konfigurasi API remote: $error');
    }
  }
  final initialSchoolId = preferences.getString(_schoolIdKey) ?? getSchoolId();
  runApp(
    MyApp(
      preferences: preferences,
      initialBaseUrl: initialBaseUrl,
      initialSchoolId: initialSchoolId,
    ),
  );
}

String getApiBaseUrl() {
  final configuredUrl = const String.fromEnvironment('API_BASE_URL').trim();
  if (configuredUrl.isNotEmpty) {
    return configuredUrl.replaceFirst(RegExp(r'/+$'), '');
  }
  return '';
}

String getSchoolId() {
  return const String.fromEnvironment('SCHOOL_ID');
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.preferences,
    required this.initialBaseUrl,
    required this.initialSchoolId,
  });

  final SharedPreferences preferences;
  final String initialBaseUrl;
  final String initialSchoolId;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final String _baseUrl = widget.initialBaseUrl;
  late String _schoolId = widget.initialSchoolId;
  late final _tenantApiConfig = TenantApiConfig(schoolId: _schoolId);
  late final _authLocalStorage = AuthLocalStorage();
  late final _authenticatedHttpClient = AuthenticatedHttpClient(
    baseUrl: _baseUrl,
    tenantApiConfig: _tenantApiConfig,
    authStorage: _authLocalStorage,
  );

  @override
  void initState() {
    super.initState();
    _tenantApiConfig.httpClient = _authenticatedHttpClient;
  }

  Future<void> _saveSchoolId(String schoolId) async {
    final normalizedSchoolId = schoolId.trim();
    _tenantApiConfig.schoolId = normalizedSchoolId;
    await widget.preferences.setString(_schoolIdKey, normalizedSchoolId);
    if (mounted) setState(() => _schoolId = normalizedSchoolId);
  }

  @override
  void dispose() {
    _authenticatedHttpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      key: ValueKey(_baseUrl),
      providers: getAppProviders(
        _baseUrl,
        _tenantApiConfig,
        authLocalStorage: _authLocalStorage,
      ),
      child: MaterialApp(
        title: 'Aplikasi Sekolah',
        theme: ThemeData(primarySwatch: Colors.teal),
        home: LoginView(
          initialSchoolId: _schoolId,
          onSchoolIdSaved: _saveSchoolId,
        ),
      ),
    );
  }
}
