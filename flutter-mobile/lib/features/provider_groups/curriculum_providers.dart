import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../e-rapor/local/rapor_local_storage.dart';
import '../e-rapor/repositories/rapor_repository.dart';
import '../e-rapor/services/rapor_service.dart';
import '../e-rapor/viewmodel/rapor_viewmodel.dart';
import '../kurikulum/assignments/local/assignment_local_storage.dart';
import '../kurikulum/assignments/repositories/assignment_repository.dart';
import '../kurikulum/assignments/services/assignment_service.dart';
import '../kurikulum/assignments/viewmodel/assignment_viewmodel.dart';
import '../kurikulum/buku-komunikasi/local/buku_komunikasi_local_storage.dart';
import '../kurikulum/buku-komunikasi/repositories/buku_komunikasi_repository.dart';
import '../kurikulum/buku-komunikasi/services/buku_komunikasi_service.dart';
import '../kurikulum/buku-komunikasi/viewmodel/buku_komunikasi_viewmodel.dart';
import '../kurikulum/cbt/local/cbt_local_storage.dart';
import '../kurikulum/cbt/repositories/cbt_repository.dart';
import '../kurikulum/cbt/services/cbt_service.dart';
import '../kurikulum/cbt/viewmodel/cbt_viewmodel.dart';
import '../kurikulum/weekly_plan/local/weekly_plan_local_storage.dart';
import '../kurikulum/weekly_plan/repositories/weekly_plan_repository.dart';
import '../kurikulum/weekly_plan/services/weekly_plan_service.dart';
import '../kurikulum/weekly_plan/viewmodel/weekly_plan_viewmodel.dart';
import '../../services/tenant_api_config.dart';

List<SingleChildWidget> createCurriculumProviders(
  String baseUrl,
  TenantApiConfig tenantApiConfig,
) => [
  Provider<CbtService>(
    create: (_) =>
        CbtService(baseUrl: baseUrl, tenantApiConfig: tenantApiConfig),
  ),
  Provider<CbtLocalStorage>(create: (_) => CbtLocalStorage()),
  ProxyProvider2<CbtService, CbtLocalStorage, CbtRepository>(
    update: (_, service, storage, _) =>
        CbtRepository(apiService: service, localStorage: storage),
  ),
  ChangeNotifierProxyProvider<CbtRepository, CbtViewModel>(
    create: (context) => CbtViewModel(
      repository: Provider.of<CbtRepository>(context, listen: false),
    ),
    update: (_, repo, previous) => previous ?? CbtViewModel(repository: repo),
  ),
  Provider<WeeklyPlanService>(
    create: (_) =>
        WeeklyPlanService(baseUrl: baseUrl, tenantApiConfig: tenantApiConfig),
  ),
  Provider<WeeklyPlanLocalStorage>(create: (_) => WeeklyPlanLocalStorage()),
  ProxyProvider2<
    WeeklyPlanService,
    WeeklyPlanLocalStorage,
    WeeklyPlanRepository
  >(
    update: (_, service, storage, _) =>
        WeeklyPlanRepository(apiService: service, localStorage: storage),
  ),
  ChangeNotifierProxyProvider<WeeklyPlanRepository, WeeklyPlanViewModel>(
    create: (context) => WeeklyPlanViewModel(
      repository: Provider.of<WeeklyPlanRepository>(context, listen: false),
    ),
    update: (_, repo, previous) =>
        previous ?? WeeklyPlanViewModel(repository: repo),
  ),
  Provider<BukuKomunikasiService>(
    create: (_) => BukuKomunikasiService(
      baseUrl: baseUrl,
      tenantApiConfig: tenantApiConfig,
    ),
  ),
  Provider<BukuKomunikasiLocalStorage>(
    create: (_) => BukuKomunikasiLocalStorage(),
  ),
  ProxyProvider2<
    BukuKomunikasiService,
    BukuKomunikasiLocalStorage,
    BukuKomunikasiRepository
  >(
    update: (_, service, storage, _) =>
        BukuKomunikasiRepository(apiService: service, localStorage: storage),
  ),
  ChangeNotifierProxyProvider<
    BukuKomunikasiRepository,
    BukuKomunikasiViewModel
  >(
    create: (context) => BukuKomunikasiViewModel(
      repository: Provider.of<BukuKomunikasiRepository>(context, listen: false),
    ),
    update: (_, repo, previous) =>
        previous ?? BukuKomunikasiViewModel(repository: repo),
  ),
  Provider<RaporService>(
    create: (_) =>
        RaporService(baseUrl: baseUrl, tenantApiConfig: tenantApiConfig),
  ),
  Provider<RaporLocalStorage>(create: (_) => RaporLocalStorage()),
  ProxyProvider2<RaporService, RaporLocalStorage, RaporRepository>(
    update: (_, service, storage, _) =>
        RaporRepository(apiService: service, localStorage: storage),
  ),
  ChangeNotifierProxyProvider<RaporRepository, RaporViewModel>(
    create: (context) => RaporViewModel(
      repository: Provider.of<RaporRepository>(context, listen: false),
    ),
    update: (_, repo, previous) => previous ?? RaporViewModel(repository: repo),
  ),
  Provider<AssignmentService>(
    create: (_) =>
        AssignmentService(baseUrl: baseUrl, tenantApiConfig: tenantApiConfig),
  ),
  Provider<AssignmentLocalStorage>(create: (_) => AssignmentLocalStorage()),
  ProxyProvider2<
    AssignmentService,
    AssignmentLocalStorage,
    AssignmentRepository
  >(
    update: (_, service, storage, _) =>
        AssignmentRepository(apiService: service, localStorage: storage),
  ),
  ChangeNotifierProxyProvider<AssignmentRepository, AssignmentViewModel>(
    create: (context) => AssignmentViewModel(
      repository: Provider.of<AssignmentRepository>(context, listen: false),
    ),
    update: (_, repo, previous) =>
        previous ?? AssignmentViewModel(repository: repo),
  ),
];
