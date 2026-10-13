import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../services/tenant_api_config.dart';
import 'provider_groups/curriculum_providers.dart';
import 'provider_groups/identity_providers.dart';
import 'provider_groups/learning_providers.dart';

List<SingleChildWidget> getAppProviders(
  String baseUrl,
  TenantApiConfig tenantApiConfig,
) => [
  Provider<TenantApiConfig>.value(value: tenantApiConfig),
  ...createIdentityProviders(baseUrl, tenantApiConfig),
  ...createLearningProviders(baseUrl, tenantApiConfig),
  ...createCurriculumProviders(baseUrl, tenantApiConfig),
];
