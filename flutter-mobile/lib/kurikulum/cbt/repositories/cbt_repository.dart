import '../services/cbt_service.dart';

class CbtRepository {
  final CbtService apiService;

  CbtRepository({required this.apiService});

  /// Mengambil daftar ujian CBT, mengembalikan list exam mentah.
  Future<List<Map<String, dynamic>>> getCbtSchedules(String token) async {
    final data = await apiService.fetchCbtSchedules(token);
    // `data` sesuai response_model: { total_exams: int, exams: [ ... ] }
    final exams = data['exams'] as List<dynamic>? ?? [];
    return exams.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
