import 'package:flutter/foundation.dart';
import '../../auth/models/auth_model.dart';
import '../models/profile_model.dart';
import '../repositories/profile_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository? repository;

  ProfileViewModel({this.repository});

  StudentProfile? _profile;
  StudentProfile? get profile => _profile;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final Map<String, Future<void>> _profileLoads = {};
  final Set<String> _profileLoadAttempts = {};
  int _profileRequestVersion = 0;

  Future<void> loadProfileOnce({
    required String token,
    required UserProfile? user,
    required String schoolId,
  }) async {
    final profileRepository = repository;
    if (profileRepository == null || user == null || token.isEmpty) return;

    final cacheKey = '${schoolId.trim()}:${user.userId}';
    _activeCacheKey = cacheKey;
    final pending = _profileLoads[cacheKey];
    if (pending != null) return pending;
    if (_profileLoadAttempts.contains(cacheKey)) return;

    final load = _loadProfile(cacheKey, token, user);
    _profileLoads[cacheKey] = load;
    try {
      await load;
    } finally {
      _profileLoads.remove(cacheKey);
    }
  }

  Future<void> _loadProfile(
    String cacheKey,
    String token,
    UserProfile user,
  ) async {
    final profileRepository = repository;
    if (profileRepository == null) return;

    final requestVersion = ++_profileRequestVersion;
    _profileLoadAttempts.add(cacheKey);
    _errorMessage = null;
    _profile = StudentProfile.fromUserProfile(user);
    notifyListeners();
    StudentProfile? cached;
    try {
      cached = await profileRepository.loadCachedProfile(cacheKey);
      if (requestVersion != _profileRequestVersion) return;
      if (cached != null) {
        _profile = cached;
        notifyListeners();
      }

      final fresh = await profileRepository.getMyProfile(token);
      if (requestVersion != _profileRequestVersion) return;
      await profileRepository.saveCachedProfile(cacheKey, fresh);
      if (requestVersion != _profileRequestVersion) return;
      _profile = fresh;
    } catch (error) {
      if (requestVersion != _profileRequestVersion) return;
      _errorMessage = cached == null
          ? error.toString().replaceAll('Exception: ', '')
          : null;
    }
    notifyListeners();
  }

  Future<void> refreshProfile(String token) async {
    final profileRepository = repository;
    if (profileRepository == null) return;

    final requestVersion = ++_profileRequestVersion;
    _errorMessage = null;
    notifyListeners();
    try {
      final fresh = await profileRepository.getMyProfile(token);
      if (requestVersion != _profileRequestVersion) return;
      final cacheKey = _activeCacheKey;
      if (cacheKey != null) {
        await profileRepository.saveCachedProfile(cacheKey, fresh);
      }
      if (requestVersion != _profileRequestVersion) return;
      _profile = fresh;
    } catch (e) {
      if (requestVersion != _profileRequestVersion) return;
      final cacheKey = _activeCacheKey;
      StudentProfile? cached;
      if (cacheKey != null) {
        cached = await profileRepository.loadCachedProfile(cacheKey);
      }
      if (requestVersion != _profileRequestVersion) return;
      if (cached != null) _profile = cached;
      _errorMessage = cached == null
          ? e.toString().replaceAll('Exception: ', '')
          : null;
    }
    notifyListeners();
  }

  String? _activeCacheKey;

  void setProfile(UserProfile? user) {
    _profile = user == null ? null : StudentProfile.fromUserProfile(user);
    _errorMessage = null;
    notifyListeners();
  }
}
