import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../auth/local/auth_local_storage.dart';
import '../auth/repositories/auth_repository.dart';
import '../auth/services/auth_service.dart';
import '../auth/viewmodel/auth_viewmodel.dart';
import '../profile/local/profile_local_storage.dart';
import '../profile/repositories/profile_repository.dart';
import '../profile/services/profile_service.dart';
import '../profile/viewmodel/profile_viewmodel.dart';
import '../../services/tenant_api_config.dart';

List<SingleChildWidget> createIdentityProviders(
  String baseUrl,
  TenantApiConfig tenantApiConfig,
) => [
  Provider<AuthService>(
    create: (_) =>
        AuthService(baseUrl: baseUrl, tenantApiConfig: tenantApiConfig),
  ),
  Provider<AuthLocalStorage>(create: (_) => AuthLocalStorage()),
  ProxyProvider2<AuthService, AuthLocalStorage, AuthRepository>(
    update: (_, service, storage, _) =>
        AuthRepository(apiService: service, localStorageService: storage),
  ),
  ChangeNotifierProxyProvider<AuthRepository, AuthViewModel>(
    create: (context) => AuthViewModel(
      repository: Provider.of<AuthRepository>(context, listen: false),
      connectivityChanges: Connectivity().onConnectivityChanged,
    ),
    update: (_, repo, previous) => previous ?? AuthViewModel(repository: repo),
  ),
  Provider<ProfileService>(
    create: (_) =>
        ProfileService(baseUrl: baseUrl, tenantApiConfig: tenantApiConfig),
  ),
  Provider<ProfileLocalStorage>(create: (_) => ProfileLocalStorage()),
  ProxyProvider2<ProfileService, ProfileLocalStorage, ProfileRepository>(
    update: (_, service, storage, _) =>
        ProfileRepository(apiService: service, localStorage: storage),
  ),
  ChangeNotifierProxyProvider<ProfileRepository, ProfileViewModel>(
    create: (context) => ProfileViewModel(
      repository: Provider.of<ProfileRepository>(context, listen: false),
    ),
    update: (_, repository, previous) =>
        previous ?? ProfileViewModel(repository: repository),
  ),
];
