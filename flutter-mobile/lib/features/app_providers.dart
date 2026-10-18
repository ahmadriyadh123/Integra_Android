import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../services/tenant_api_config.dart';
import 'auth/local/auth_local_storage.dart';
import 'notification/services/notification_service.dart';
import 'notification/viewmodel/notification_viewmodel.dart';
import 'provider_groups/curriculum_providers.dart';
import 'provider_groups/identity_providers.dart';
import 'provider_groups/learning_providers.dart';

List<SingleChildWidget> getAppProviders(
  String baseUrl,
  TenantApiConfig tenantApiConfig,
  {AuthLocalStorage? authLocalStorage}
) => [
  Provider<TenantApiConfig>.value(value: tenantApiConfig),
  ...createIdentityProviders(
    baseUrl,
    tenantApiConfig,
    authLocalStorage: authLocalStorage,
  ),
  ...createLearningProviders(baseUrl, tenantApiConfig),
  ...createCurriculumProviders(baseUrl, tenantApiConfig),
  Provider<NotificationService>(
    create: (_) => NotificationService(
      baseUrl: baseUrl,
      tenantApiConfig: tenantApiConfig,
    ),
  ),
  ChangeNotifierProxyProvider<NotificationService, NotificationViewModel>(
    create: (context) => NotificationViewModel(),
    update: (_, service, previous) {
      final vm = previous ?? NotificationViewModel();
      vm.configure(service);
      return vm;
    },
  ),
];
