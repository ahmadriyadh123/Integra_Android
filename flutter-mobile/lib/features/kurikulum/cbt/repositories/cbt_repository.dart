import '../local/cbt_local_storage.dart';
import '../services/cbt_service.dart';

class CbtRepository {
  final CbtService apiService;
  final CbtLocalStorage localStorage;

  CbtRepository({
    required this.apiService,
    required this.localStorage,
  });

  /// Mengambil daftar ujian CBT dengan cache-first strategy.
  /// Mengembalikan list exam mentah.
  Future<List<Map<String, dynamic>>> getCbtSchedules(String token,
      {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await localStorage.loadCbtSchedules();
      if (cached != null) {
        return cached
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    }

    final data = await apiService.fetchCbtSchedules(token);
    final exams = data['exams'] as List<dynamic>? ?? [];
    final schedules = exams.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    await localStorage.saveCbtSchedules(schedules);

    return schedules;
  }

  /// Verifikasi token ke API
  Future<bool> verifyToken(String token, int jadwalId, String tokenInput) async {
    return await apiService.verifyExamToken(token, jadwalId, tokenInput);
  }

  /// Ambil soal ujian dari API
  Future<Map<String, dynamic>> getExamQuestions(String token, int jadwalId) async {
    return await apiService.fetchExamQuestions(token, jadwalId);
  }

  /// Submit jawaban ujian ke API
  Future<Map<String, dynamic>> submitExam(
    String token,
    int jadwalId,
    List<Map<String, dynamic>> answers,
    String? waktuMulai,
  ) async {
    return await apiService.submitExam(token, jadwalId, answers, waktuMulai);
  }
}

