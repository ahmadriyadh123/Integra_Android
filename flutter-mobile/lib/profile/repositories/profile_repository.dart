import 'dart:typed_data';

import '../models/profile_model.dart';
import '../services/profile_service.dart';

class ProfileRepository {
  final ProfileService apiService;

  ProfileRepository({required this.apiService});

  Future<StudentProfile> getMyProfile(String token) async {
    final data = await apiService.getMyProfile(token);
    return StudentProfile.fromJson(data);
  }

  Future<Uint8List> getProfileImage(String token, int partnerId) {
    return apiService.getProfileImage(token, partnerId);
  }
}
