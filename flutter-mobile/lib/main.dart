import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_application_1/features/auth/view/login_view.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/app_providers.dart';
import 'services/tenant_api_config.dart';

const _apiBaseUrlKey = 'api_base_url';
const _schoolIdKey = 'school_id';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final preferences = await SharedPreferences.getInstance();
  final configuredBaseUrl = getApiBaseUrl();
  final initialBaseUrl = configuredBaseUrl.isNotEmpty
      ? configuredBaseUrl
      : preferences.getString(_apiBaseUrlKey) ?? '';
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
  if (kIsWeb) return Uri.base.resolve('/api/v1').toString();
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
  late String _baseUrl = widget.initialBaseUrl;
  late String _schoolId = widget.initialSchoolId;
  late final _tenantApiConfig = TenantApiConfig(schoolId: _schoolId);

  Future<void> _saveSchoolId(String schoolId) async {
    final normalizedSchoolId = schoolId.trim();
    _tenantApiConfig.schoolId = normalizedSchoolId;
    await widget.preferences.setString(_schoolIdKey, normalizedSchoolId);
    if (mounted) setState(() => _schoolId = normalizedSchoolId);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      key: ValueKey(_baseUrl),
      providers: getAppProviders(_baseUrl, _tenantApiConfig),
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
