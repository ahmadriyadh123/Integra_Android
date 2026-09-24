import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/auth/view/login_view.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/app_providers.dart';

const _apiBaseUrlKey = 'api_base_url';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final preferences = await SharedPreferences.getInstance();
  runApp(
    MyApp(
      preferences: preferences,
      initialBaseUrl: preferences.getString(_apiBaseUrlKey) ?? getApiBaseUrl(),
    ),
  );
}

String getApiBaseUrl() {
  return const String.fromEnvironment('API_BASE_URL');
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.preferences,
    required this.initialBaseUrl,
  });

  final SharedPreferences preferences;
  final String initialBaseUrl;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late String _baseUrl = widget.initialBaseUrl;

  Future<void> _saveBaseUrl(String baseUrl) async {
    await widget.preferences.setString(_apiBaseUrlKey, baseUrl);
    if (mounted) setState(() => _baseUrl = baseUrl);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      key: ValueKey(_baseUrl),
      providers: getAppProviders(_baseUrl),
      child: MaterialApp(
        title: 'Aplikasi Sekolah',
        theme: ThemeData(primarySwatch: Colors.teal),
        home: LoginView(initialBaseUrl: _baseUrl, onServerSaved: _saveBaseUrl),
      ),
    );
  }
}
