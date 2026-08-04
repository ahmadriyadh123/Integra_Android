import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'kehadiran/services/attendance_service.dart';
import 'kehadiran/repositories/attendance_repository.dart';
import 'kehadiran/viewmodel/attendance_viewmodel.dart';
import 'dashboard/dashboard_view.dart';

void main() {
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
    const String authToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOjE3LCJ1c2VybmFtZSI6InNpc3dhMkBnbWFpbC5jb20iLCJwYXNzd29yZCI6IjEyMzRvc2siLCJleHAiOjE3ODg0MDg1MTR9.gxD17rsy-G_PUGG-SoA1q3lB7Dc8UAKfF9ZwTESogPY";

    return MultiProvider(
      providers: [
        // 1. Inisialisasi Service & Repository
        Provider<AttendanceService>(
          create: (_) => AttendanceService(baseUrl: baseUrl),
        ),
        ProxyProvider<AttendanceService, AttendanceRepository>(
          update: (_, service, _) => AttendanceRepository(apiService: service),
        ),

        // 2. Inisialisasi ViewModel (ChangeNotifier)
        ChangeNotifierProxyProvider<AttendanceRepository, AttendanceViewModel>(
          create: (context) => AttendanceViewModel(
            repository: Provider.of<AttendanceRepository>(context, listen: false),
          ),
          update: (_, repo, previous) => previous ?? AttendanceViewModel(repository: repo),
        ),
      ],
      child: MaterialApp(
        title: 'Aplikasi Sekolah',
        theme: ThemeData(
          primarySwatch: Colors.teal,
        ),
        home: const DashboardView(
          authToken: authToken,
        ),
      ),
    );
  }
}