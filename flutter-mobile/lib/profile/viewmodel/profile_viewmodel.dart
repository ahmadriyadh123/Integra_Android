import 'package:flutter/foundation.dart';
import '../models/profile_model.dart';
import '../repositories/profile_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository repository;

  ProfileViewModel({required this.repository});

  StudentProfile? _profile;
  StudentProfile? get profile => _profile;

  Uint8List? _profileImage;
  Uint8List? get profileImage => _profileImage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile(String token, {int? fallbackPartnerId}) async {
    if (token.isEmpty || _isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await repository.getMyProfile(token);
      final partnerId = _profile?.partnerId ?? fallbackPartnerId;
      if (partnerId != null && partnerId > 0) {
        await loadProfileImage(token, partnerId);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProfileImage(String token, int? partnerId) async {
    if (token.isEmpty || partnerId == null || partnerId <= 0) return;
    try {
      _profileImage = await repository.getProfileImage(token, partnerId);
    } catch (_) {
      _profileImage = null;
    }
    notifyListeners();
  }
}
