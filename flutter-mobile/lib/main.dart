import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'auth/view/login_view.dart';
import 'app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const MyApp());
}

String getApiBaseUrl() {
  const overrideBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  if (overrideBaseUrl.isNotEmpty) {
    return overrideBaseUrl;
  }

  if (kIsWeb) {
    return 'http://localhost:8000/api/v1';
  }

  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000/api/v1';
  }

  if (Platform.isIOS) {
    return 'http://127.0.0.1:8000/api/v1';
  }

  return 'http://localhost:8000/api/v1';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final String baseUrl = getApiBaseUrl();

    return MultiProvider(
      providers: getAppProviders(baseUrl),
      child: MaterialApp(
        title: 'Aplikasi Sekolah',
        theme: ThemeData(
          primarySwatch: Colors.teal,
        ),
        // Halaman pertama adalah LoginView
        home: const SplashScreen(),
      ),
    );
  }
}
