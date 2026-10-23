import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../data/local/auth/auth_local_storage.dart';
import '../../data/repositories/auth/auth_repository.dart';
import '../../data/services/auth/auth_service.dart';
import '../../ui/auth/view_models/auth_viewmodel.dart';
import '../../data/local/profile/profile_local_storage.dart';
import '../../data/repositories/profile/profile_repository.dart';
import '../../data/services/profile/profile_service.dart';
import '../../ui/profile/view_models/profile_viewmodel.dart';
import '../api/tenant_api_config.dart';

List<SingleChildWidget> createIdentityProviders(
  String baseUrl,
  TenantApiConfig tenantApiConfig, {
  AuthLocalStorage? authLocalStorage,
}) => [
  Provider<AuthService>(
    create: (_) =>
        AuthService(baseUrl: baseUrl, tenantApiConfig: tenantApiConfig),
  ),
  Provider<AuthLocalStorage>.value(
    value: authLocalStorage ?? AuthLocalStorage(),
  ),
  ProxyProvider2<AuthService, AuthLocalStorage, AuthRepository>(
    update: (_, service, storage, _) =>
        AuthRepository(apiService: service, localStorageService: storage),
  ),
  ChangeNotifierProxyProvider<AuthRepository, AuthViewModel>(
    create: (context) {
      final viewModel = AuthViewModel(
        repository: Provider.of<AuthRepository>(context, listen: false),
        connectivityChanges: Connectivity().onConnectivityChanged,
      );
      tenantApiConfig.onSessionExpired = viewModel.handleSessionExpired;
      return viewModel;
    },
    update: (_, repo, previous) {
      final viewModel = previous ?? AuthViewModel(repository: repo);
      tenantApiConfig.onSessionExpired = viewModel.handleSessionExpired;
      return viewModel;
    },
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
