import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../calendar/local/calendar_local_storage.dart';
import '../calendar/repositories/calendar_repository.dart';
import '../calendar/services/calendar_service.dart';
import '../calendar/viewmodel/calendar_viewmodel.dart';
import '../elearning/local/elearning_local_storage.dart';
import '../elearning/repositories/elearning_repository.dart';
import '../elearning/services/elearning_service.dart';
import '../elearning/viewmodel/elearning_viewmodel.dart';
import '../kehadiran/local/attendance_local_storage.dart';
import '../kehadiran/repositories/attendance_repository.dart';
import '../kehadiran/services/attendance_service.dart';
import '../kehadiran/viewmodel/attendance_viewmodel.dart';
import '../tagihan/local/tagihan_local_storage.dart';
import '../tagihan/repositories/tagihan_repository.dart';
import '../tagihan/services/tagihan_service.dart';
import '../tagihan/viewmodel/tagihan_viewmodel.dart';
import '../../services/tenant_api_config.dart';

List<SingleChildWidget> createLearningProviders(
  String baseUrl,
  TenantApiConfig tenantApiConfig,
) => [
  Provider<AttendanceService>(
    create: (_) =>
        AttendanceService(baseUrl: baseUrl, tenantApiConfig: tenantApiConfig),
  ),
  Provider<AttendanceLocalStorage>(create: (_) => AttendanceLocalStorage()),
  ProxyProvider2<
    AttendanceService,
    AttendanceLocalStorage,
    AttendanceRepository
  >(
    update: (_, service, storage, _) =>
        AttendanceRepository(apiService: service, localStorage: storage),
  ),
  ChangeNotifierProxyProvider<AttendanceRepository, AttendanceViewModel>(
    create: (context) => AttendanceViewModel(
      repository: Provider.of<AttendanceRepository>(context, listen: false),
    ),
    update: (_, repo, previous) =>
        previous ?? AttendanceViewModel(repository: repo),
  ),
  Provider<CalendarService>(
    create: (_) =>
        CalendarService(baseUrl: baseUrl, tenantApiConfig: tenantApiConfig),
  ),
  Provider<CalendarLocalStorage>(create: (_) => CalendarLocalStorage()),
  ProxyProvider2<CalendarService, CalendarLocalStorage, CalendarRepository>(
    update: (_, service, storage, _) =>
        CalendarRepository(apiService: service, localStorage: storage),
  ),
  ChangeNotifierProxyProvider<CalendarRepository, CalendarViewModel>(
    create: (context) => CalendarViewModel(
      repository: Provider.of<CalendarRepository>(context, listen: false),
    ),
    update: (_, repo, previous) => previous ?? CalendarViewModel(repository: repo),
  ),
  Provider<ElearningService>(
    create: (_) =>
        ElearningService(baseUrl: baseUrl, tenantApiConfig: tenantApiConfig),
  ),
  Provider<ElearningLocalStorage>(create: (_) => ElearningLocalStorage()),
  ProxyProvider2<ElearningService, ElearningLocalStorage, ElearningRepository>(
    update: (_, service, storage, _) =>
        ElearningRepository(apiService: service, localStorage: storage),
  ),
  ChangeNotifierProxyProvider<ElearningRepository, ElearningViewModel>(
    create: (context) => ElearningViewModel(
      repository: Provider.of<ElearningRepository>(context, listen: false),
    ),
    update: (_, repo, previous) =>
        previous ?? ElearningViewModel(repository: repo),
  ),
  Provider<TagihanService>(
    create: (_) =>
        TagihanService(baseUrl: baseUrl, tenantApiConfig: tenantApiConfig),
  ),
  Provider<TagihanLocalStorage>(create: (_) => TagihanLocalStorage()),
  ProxyProvider2<TagihanService, TagihanLocalStorage, TagihanRepository>(
    update: (_, service, storage, _) =>
        TagihanRepository(apiService: service, localStorage: storage),
  ),
  ChangeNotifierProxyProvider<TagihanRepository, TagihanViewModel>(
    create: (context) => TagihanViewModel(
      repository: Provider.of<TagihanRepository>(context, listen: false),
    ),
    update: (_, repo, previous) => previous ?? TagihanViewModel(repository: repo),
  ),
];
