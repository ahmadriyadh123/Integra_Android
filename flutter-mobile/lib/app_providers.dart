import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'auth/local/auth_local_storage.dart';
import 'auth/services/auth_service.dart';
import 'auth/repositories/auth_repository.dart';
import 'auth/viewmodel/auth_viewmodel.dart';

import 'kehadiran/local/attendance_local_storage.dart';
import 'kehadiran/services/attendance_service.dart';
import 'kehadiran/repositories/attendance_repository.dart';
import 'kehadiran/viewmodel/attendance_viewmodel.dart';

import 'calendar/local/calendar_local_storage.dart';
import 'calendar/services/calendar_service.dart';
import 'calendar/repositories/calendar_repository.dart';
import 'calendar/viewmodel/calendar_viewmodel.dart';

import 'elearning/services/elearning_service.dart';
import 'elearning/repositories/elearning_repository.dart';
import 'elearning/viewmodel/elearning_viewmodel.dart';
import 'elearning/local/elearning_local_storage.dart';

import 'tagihan/services/tagihan_service.dart';
import 'tagihan/local/tagihan_local_storage.dart';
import 'tagihan/repositories/tagihan_repository.dart';
import 'tagihan/viewmodel/tagihan_viewmodel.dart';

import 'kurikulum/weekly_plan/local/weekly_plan_local_storage.dart';
import 'kurikulum/weekly_plan/services/weekly_plan_service.dart';
import 'kurikulum/weekly_plan/repositories/weekly_plan_repository.dart';
import 'kurikulum/weekly_plan/viewmodel/weekly_plan_viewmodel.dart';

import 'kurikulum/buku-komunikasi/local/buku_komunikasi_local_storage.dart';
import 'kurikulum/buku-komunikasi/services/buku_komunikasi_service.dart';
import 'kurikulum/buku-komunikasi/repositories/buku_komunikasi_repository.dart';
import 'kurikulum/buku-komunikasi/viewmodel/buku_komunikasi_viewmodel.dart';

import 'e-rapor/local/rapor_local_storage.dart';
import 'e-rapor/services/rapor_service.dart';
import 'e-rapor/repositories/rapor_repository.dart';
import 'e-rapor/viewmodel/rapor_viewmodel.dart';

import 'kurikulum/cbt/local/cbt_local_storage.dart';
import 'kurikulum/cbt/services/cbt_service.dart';
import 'kurikulum/cbt/repositories/cbt_repository.dart';
import 'kurikulum/cbt/viewmodel/cbt_viewmodel.dart';

/// Mengembalikan daftar semua provider yang digunakan dalam aplikasi.
/// Memisahkan logika ini dari main.dart menjaga agar struktur kode main.dart tetap bersih dan terorganisir.
List<SingleChildWidget> getAppProviders(String baseUrl) {
  return [
    // --- Auth ---
    Provider<AuthService>(
      create: (_) => AuthService(baseUrl: baseUrl),
    ),
    Provider<AuthLocalStorage>(
      create: (_) => AuthLocalStorage(),
    ),
    ProxyProvider<AuthService, AuthRepository>(
      update: (_, service, __) => AuthRepository(apiService: service),
    ),
    ChangeNotifierProxyProvider2<AuthRepository, AuthLocalStorage, AuthViewModel>(
      create: (context) => AuthViewModel(
        repository: Provider.of<AuthRepository>(context, listen: false),
        localStorage: Provider.of<AuthLocalStorage>(context, listen: false),
      ),
      update: (_, repo, storage, previous) =>
          previous ?? AuthViewModel(repository: repo, localStorage: storage),
    ),

    // --- Kehadiran (Attendance) ---
    Provider<AttendanceService>(
      create: (_) => AttendanceService(baseUrl: baseUrl),
    ),
    Provider<AttendanceLocalStorage>(
      create: (_) => AttendanceLocalStorage(),
    ),
    ProxyProvider2<AttendanceService, AttendanceLocalStorage, AttendanceRepository>(
      update: (_, service, storage, __) => AttendanceRepository(
        apiService: service,
        localStorage: storage,
      ),
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
    Provider<CalendarLocalStorage>(
      create: (_) => CalendarLocalStorage(),
    ),
    ProxyProvider2<CalendarService, CalendarLocalStorage, CalendarRepository>(
      update: (_, service, storage, __) => CalendarRepository(
        apiService: service,
        localStorage: storage,
      ),
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
    ProxyProvider2<ElearningService, ElearningLocalStorage, ElearningRepository>(
      update: (_, service, storage, __) => ElearningRepository(
        apiService: service,
        localStorage: storage,
      ),
    ),
    ChangeNotifierProxyProvider2<ElearningRepository, ElearningLocalStorage, ElearningViewModel>(
      create: (context) => ElearningViewModel(
        repository: Provider.of<ElearningRepository>(context, listen: false),
        localStorage: Provider.of<ElearningLocalStorage>(context, listen: false),
      ),
      update: (_, repo, storage, previous) =>
          previous ?? ElearningViewModel(repository: repo, localStorage: storage),
    ),

    // --- CBT (Ujian) ---
    Provider<CbtService>(
      create: (_) => CbtService(baseUrl: baseUrl),
    ),
    Provider<CbtLocalStorage>(
      create: (_) => CbtLocalStorage(),
    ),
    ProxyProvider2<CbtService, CbtLocalStorage, CbtRepository>(
      update: (_, service, storage, __) => CbtRepository(
        apiService: service,
        localStorage: storage,
      ),
    ),
    ChangeNotifierProxyProvider<CbtRepository, CbtViewModel>(
      create: (context) => CbtViewModel(
        repository: Provider.of<CbtRepository>(context, listen: false),
      ),
      update: (_, repo, previous) => previous ?? CbtViewModel(repository: repo),
    ),

    // --- Tagihan (Invoices) ---
    Provider<TagihanService>(
      create: (_) => TagihanService(baseUrl: baseUrl),
    ),
    Provider<TagihanLocalStorage>(
      create: (_) => TagihanLocalStorage(),
    ),
    ProxyProvider2<TagihanService, TagihanLocalStorage, TagihanRepository>(
      update: (_, service, storage, __) => TagihanRepository(
        apiService: service,
        localStorage: storage,
      ),
    ),
    ChangeNotifierProxyProvider<TagihanRepository, TagihanViewModel>(
      create: (context) => TagihanViewModel(
        repository: Provider.of<TagihanRepository>(context, listen: false),
      ),
      update: (_, repo, previous) =>
          previous ?? TagihanViewModel(repository: repo),
    ),
    // --- Weekly Plan ---
    Provider<WeeklyPlanService>(
      create: (_) => WeeklyPlanService(baseUrl: baseUrl),
    ),
    Provider<WeeklyPlanLocalStorage>(
      create: (_) => WeeklyPlanLocalStorage(),
    ),
    ProxyProvider2<WeeklyPlanService, WeeklyPlanLocalStorage, WeeklyPlanRepository>(
      update: (_, service, storage, __) => WeeklyPlanRepository(
        apiService: service,
        localStorage: storage,
      ),
    ),
    ChangeNotifierProxyProvider<WeeklyPlanRepository, WeeklyPlanViewModel>(
      create: (context) => WeeklyPlanViewModel(
        repository:
            Provider.of<WeeklyPlanRepository>(context, listen: false),
      ),
      update: (_, repo, previous) =>
          previous ?? WeeklyPlanViewModel(repository: repo),
    ),

    // --- Buku Komunikasi ---
    Provider<BukuKomunikasiService>(
      create: (_) => BukuKomunikasiService(baseUrl: baseUrl),
    ),
    Provider<BukuKomunikasiLocalStorage>(
      create: (_) => BukuKomunikasiLocalStorage(),
    ),
    ProxyProvider2<BukuKomunikasiService, BukuKomunikasiLocalStorage, BukuKomunikasiRepository>(
      update: (_, service, storage, __) => BukuKomunikasiRepository(
        apiService: service,
        localStorage: storage,
      ),
    ),
    ChangeNotifierProxyProvider<BukuKomunikasiRepository, BukuKomunikasiViewModel>(
      create: (context) => BukuKomunikasiViewModel(
        repository: Provider.of<BukuKomunikasiRepository>(context, listen: false),
      ),
      update: (_, repo, previous) =>
          previous ?? BukuKomunikasiViewModel(repository: repo),
    ),

    // --- E-Rapor ---
    Provider<RaporService>(
      create: (_) => RaporService(baseUrl: baseUrl),
    ),
    Provider<RaporLocalStorage>(
      create: (_) => RaporLocalStorage(),
    ),
    ProxyProvider2<RaporService, RaporLocalStorage, RaporRepository>(
      update: (_, service, storage, __) => RaporRepository(
        apiService: service,
        localStorage: storage,
      ),
    ),
    ChangeNotifierProxyProvider<RaporRepository, RaporViewModel>(
      create: (context) => RaporViewModel(
        repository: Provider.of<RaporRepository>(context, listen: false),
      ),
      update: (_, repo, previous) =>
          previous ?? RaporViewModel(repository: repo),
    ),
  ];
}
