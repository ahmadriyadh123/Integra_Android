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

    _profileLoadAttempts.add(cacheKey);
    _errorMessage = null;
    _profile = StudentProfile.fromUserProfile(user);
    notifyListeners();
    try {
      final cached = await profileRepository.loadCachedProfile(cacheKey);
      if (cached != null) {
        _profile = cached;
        notifyListeners();
        return;
      }

      final fresh = await profileRepository.getMyProfile(token);
      await profileRepository.saveCachedProfile(cacheKey, fresh);
      _profile = fresh;
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> refreshProfile(String token) async {
    final profileRepository = repository;
    if (profileRepository == null) return;

    _errorMessage = null;
    try {
      final fresh = await profileRepository.getMyProfile(token);
      final cacheKey = _activeCacheKey;
      if (cacheKey != null) {
        await profileRepository.saveCachedProfile(cacheKey, fresh);
      }
      _profile = fresh;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
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
