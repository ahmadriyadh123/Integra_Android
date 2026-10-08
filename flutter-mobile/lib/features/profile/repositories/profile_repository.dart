import 'dart:typed_data';

import '../models/profile_model.dart';
import '../services/profile_service.dart';
import '../local/profile_local_storage.dart';

class ProfileRepository {
  final ProfileService apiService;
  final ProfileLocalStorage localStorage;

  ProfileRepository({
    required this.apiService,
    ProfileLocalStorage? localStorage,
  }) : localStorage = localStorage ?? ProfileLocalStorage();

  /// Get base URL from the service
  String get baseUrl => apiService.baseUrl;

  Future<StudentProfile> getMyProfile(String token) async {
    final data = await apiService.getMyProfile(token);
    return StudentProfile.fromJson(data);
  }

  Future<StudentProfile?> loadCachedProfile(String cacheKey) async {
    final data = await localStorage.loadProfile(cacheKey);
    return data == null ? null : StudentProfile.fromJson(data);
  }

  Future<void> saveCachedProfile(
    String cacheKey,
    StudentProfile profile,
  ) {
    return localStorage.saveProfile(cacheKey, {
      'id': profile.id,
      'user_id': profile.userId,
      'partner_id': profile.partnerId,
      'foto_siswa': profile.photoUrl,
      'nama_lengkap': profile.name,
      'nis': profile.nis,
      'nisn': profile.nisn,
      'kelas': profile.className,
      'rombel': profile.rombel,
      'tempat_tanggal_lahir': profile.tempatTanggalLahir,
      'usia': profile.usia,
      'status_aktif': profile.isActive,
    });
  }

  Future<Uint8List> getProfileImage(String token, int partnerId) {
    return apiService.getProfileImage(token, partnerId);
  }
}
