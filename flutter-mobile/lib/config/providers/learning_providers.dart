import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../data/local/calendar/calendar_local_storage.dart';
import '../../data/repositories/calendar/calendar_repository.dart';
import '../../data/services/calendar/calendar_service.dart';
import '../../ui/calendar/view_models/calendar_viewmodel.dart';
import '../../data/local/elearning/elearning_local_storage.dart';
import '../../data/repositories/elearning/elearning_repository.dart';
import '../../data/services/elearning/elearning_service.dart';
import '../../ui/elearning/view_models/elearning_viewmodel.dart';
import '../../data/local/kehadiran/attendance_local_storage.dart';
import '../../data/repositories/kehadiran/attendance_repository.dart';
import '../../data/services/kehadiran/attendance_service.dart';
import '../../ui/kehadiran/view_models/attendance_viewmodel.dart';
import '../../data/local/tagihan/tagihan_local_storage.dart';
import '../../data/repositories/tagihan/tagihan_repository.dart';
import '../../data/services/tagihan/tagihan_service.dart';
import '../../ui/tagihan/view_models/tagihan_viewmodel.dart';
import '../api/tenant_api_config.dart';

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
