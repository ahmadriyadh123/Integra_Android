import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/auth/view/login_view.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/app_providers.dart';

const _apiBaseUrlKey = 'api_base_url';
const _apiBaseUrlsKey = 'api_base_urls';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final preferences = await SharedPreferences.getInstance();
  final initialBaseUrl =
      preferences.getString(_apiBaseUrlKey) ?? getApiBaseUrl();
  final savedBaseUrls =
      preferences.getStringList(_apiBaseUrlsKey) ?? <String>[];
  if (initialBaseUrl.isNotEmpty && !savedBaseUrls.contains(initialBaseUrl)) {
    savedBaseUrls.insert(0, initialBaseUrl);
  }
  runApp(
    MyApp(
      preferences: preferences,
      initialBaseUrl: initialBaseUrl,
      savedBaseUrls: savedBaseUrls,
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
    required this.savedBaseUrls,
  });

  final SharedPreferences preferences;
  final String initialBaseUrl;
  final List<String> savedBaseUrls;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late String _baseUrl = widget.initialBaseUrl;
  late List<String> _savedBaseUrls = List<String>.from(widget.savedBaseUrls);

  Future<void> _saveBaseUrl(String baseUrl) async {
    final updatedBaseUrls = <String>[
      baseUrl,
      ..._savedBaseUrls.where((savedUrl) => savedUrl != baseUrl),
    ];
    if (updatedBaseUrls.length > 10) {
      updatedBaseUrls.removeRange(10, updatedBaseUrls.length);
    }
    await widget.preferences.setString(_apiBaseUrlKey, baseUrl);
    await widget.preferences.setStringList(_apiBaseUrlsKey, updatedBaseUrls);
    if (mounted) {
      setState(() {
        _baseUrl = baseUrl;
        _savedBaseUrls = updatedBaseUrls;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      key: ValueKey(_baseUrl),
      providers: getAppProviders(_baseUrl),
      child: MaterialApp(
        title: 'Aplikasi Sekolah',
        theme: ThemeData(primarySwatch: Colors.teal),
        home: LoginView(
          initialBaseUrl: _baseUrl,
          savedBaseUrls: _savedBaseUrls,
          onServerSaved: _saveBaseUrl,
        ),
      ),
    );
  }
}
