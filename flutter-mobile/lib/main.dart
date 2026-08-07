import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/services/auth_service.dart';
import 'auth/repositories/auth_repository.dart';
import 'auth/viewmodel/auth_viewmodel.dart';
import 'auth/view/login_view.dart';

import 'kehadiran/services/attendance_service.dart';
import 'kehadiran/repositories/attendance_repository.dart';
import 'kehadiran/viewmodel/attendance_viewmodel.dart';

import 'calendar/services/calendar_service.dart';
import 'calendar/repositories/calendar_repository.dart';
import 'calendar/viewmodel/calendar_viewmodel.dart';

import 'elearning/services/elearning_service.dart';
import 'elearning/repositories/elearning_repository.dart';
import 'elearning/viewmodel/elearning_viewmodel.dart';
import 'elearning/local/elearning_local_storage.dart';

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

    return MultiProvider(
      providers: [
        // --- Auth ---
        Provider<AuthService>(
          create: (_) => AuthService(baseUrl: baseUrl),
        ),
        ProxyProvider<AuthService, AuthRepository>(
          update: (_, service, __) => AuthRepository(apiService: service),
        ),
        ChangeNotifierProxyProvider<AuthRepository, AuthViewModel>(
          create: (context) => AuthViewModel(
            repository: Provider.of<AuthRepository>(context, listen: false),
          ),
          update: (_, repo, previous) =>
              previous ?? AuthViewModel(repository: repo),
        ),

        // --- Kehadiran ---
        Provider<AttendanceService>(
          create: (_) => AttendanceService(baseUrl: baseUrl),
        ),
        ProxyProvider<AttendanceService, AttendanceRepository>(
          update: (_, service, __) => AttendanceRepository(apiService: service),
        ),
        ChangeNotifierProxyProvider<AttendanceRepository, AttendanceViewModel>(
          create: (context) => AttendanceViewModel(
            repository: Provider.of<AttendanceRepository>(context, listen: false),
          ),
          update: (_, repo, previous) =>
              previous ?? AttendanceViewModel(repository: repo),
        ),

        // --- Kalender Akademik ---
        Provider<CalendarService>(
          create: (_) => CalendarService(baseUrl: baseUrl),
        ),
        ProxyProvider<CalendarService, CalendarRepository>(
          update: (_, service, __) => CalendarRepository(apiService: service),
        ),
        ChangeNotifierProxyProvider<CalendarRepository, CalendarViewModel>(
          create: (context) => CalendarViewModel(
            repository: Provider.of<CalendarRepository>(context, listen: false),
          ),
          update: (_, repo, previous) =>
              previous ?? CalendarViewModel(repository: repo),
        ),

        // --- E-Learning ---
        Provider<ElearningService>(
          create: (_) => ElearningService(baseUrl: baseUrl),
        ),
        Provider<ElearningLocalStorage>(
          create: (_) => ElearningLocalStorage(),
        ),
        ProxyProvider<ElearningService, ElearningRepository>(
          update: (_, service, __) => ElearningRepository(apiService: service),
        ),
        ChangeNotifierProxyProvider2<ElearningRepository, ElearningLocalStorage, ElearningViewModel>(
          create: (context) => ElearningViewModel(
            repository: Provider.of<ElearningRepository>(context, listen: false),
            localStorage: Provider.of<ElearningLocalStorage>(context, listen: false),
          ),
          update: (_, repo, storage, previous) =>
              previous ?? ElearningViewModel(repository: repo, localStorage: storage),
        ),
      ],
      child: MaterialApp(
        title: 'Aplikasi Sekolah',
        theme: ThemeData(
          primarySwatch: Colors.teal,
        ),
        // Halaman pertama adalah LoginView
        home: const LoginView(),
      ),
    );
  }
}
