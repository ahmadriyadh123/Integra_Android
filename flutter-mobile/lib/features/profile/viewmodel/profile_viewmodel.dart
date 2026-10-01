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

  Future<void> refreshProfile(String token) async {
    final profileRepository = repository;
    if (profileRepository == null) return;

    _errorMessage = null;
    try {
      _profile = await profileRepository.getMyProfile(token);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }
    notifyListeners();
  }

  void setProfile(UserProfile? user) {
    _profile = user == null ? null : StudentProfile.fromUserProfile(user);
    _errorMessage = null;
    notifyListeners();
  }
}
