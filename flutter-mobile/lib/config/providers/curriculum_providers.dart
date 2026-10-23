import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../data/local/e-rapor/rapor_local_storage.dart';
import '../../data/repositories/e-rapor/rapor_repository.dart';
import '../../data/services/e-rapor/rapor_service.dart';
import '../../ui/e-rapor/view_models/rapor_viewmodel.dart';
import '../../data/local/kurikulum/assignments/assignment_local_storage.dart';
import '../../data/repositories/kurikulum/assignments/assignment_repository.dart';
import '../../data/services/kurikulum/assignments/assignment_service.dart';
import '../../ui/kurikulum/assignments/view_models/assignment_viewmodel.dart';
import '../../data/local/kurikulum/buku-komunikasi/buku_komunikasi_local_storage.dart';
import '../../data/repositories/kurikulum/buku-komunikasi/buku_komunikasi_repository.dart';
import '../../data/services/kurikulum/buku-komunikasi/buku_komunikasi_service.dart';
import '../../ui/kurikulum/buku-komunikasi/view_models/buku_komunikasi_viewmodel.dart';
import '../../data/local/kurikulum/cbt/cbt_local_storage.dart';
import '../../data/repositories/kurikulum/cbt/cbt_repository.dart';
import '../../data/services/kurikulum/cbt/cbt_service.dart';
import '../../ui/kurikulum/cbt/view_models/cbt_viewmodel.dart';
import '../../data/local/kurikulum/weekly_plan/weekly_plan_local_storage.dart';
import '../../data/repositories/kurikulum/weekly_plan/weekly_plan_repository.dart';
import '../../data/services/kurikulum/weekly_plan/weekly_plan_service.dart';
import '../../ui/kurikulum/weekly_plan/view_models/weekly_plan_viewmodel.dart';
import '../api/tenant_api_config.dart';

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
