import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/auth/view/login_view.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'features/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const MyApp());
}

String getApiBaseUrl() {
  // Setiap build sekolah harus menunjuk ke middleware sekolah tersebut.
  const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  if (apiBaseUrl.isEmpty) {
    throw StateError(
      'API_BASE_URL belum dikonfigurasi. Gunakan --dart-define=API_BASE_URL=...',
    );
  }
  return apiBaseUrl;
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
        home: const LoginView(),
      ),
    );
  }
}
