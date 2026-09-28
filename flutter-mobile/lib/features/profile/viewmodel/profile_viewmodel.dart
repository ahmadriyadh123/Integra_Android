import 'package:flutter/foundation.dart';
import '../../auth/models/auth_model.dart';
import '../models/profile_model.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel();

  StudentProfile? _profile;
  StudentProfile? get profile => _profile;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setProfile(UserProfile? user) {
    _profile = user == null ? null : StudentProfile.fromUserProfile(user);
    _errorMessage = null;
    notifyListeners();
  }
}
