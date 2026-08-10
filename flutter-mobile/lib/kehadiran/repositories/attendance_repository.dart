import '../local/attendance_local_storage.dart';
import '../models/attendance_record.dart';
import '../services/attendance_service.dart';

class AttendanceRepository {
  final AttendanceService apiService;
  final AttendanceLocalStorage localStorage;

  AttendanceRepository({
    required this.apiService,
    required this.localStorage,
  });

  /// Mengambil data kehadiran dengan strategi Cache-First dan fallback Offline.
  Future<List<AttendanceRecord>> getAttendanceHistory(String token, {bool forceRefresh = false}) async {
    // 1. Coba load dari cache Hive terlebih dahulu (kecuali dipaksa refresh)
    if (!forceRefresh) {
      try {
        final cachedList = await localStorage.loadAttendanceHistory();
        if (cachedList != null) {
          return cachedList.map((item) => AttendanceRecord.fromJson(item)).toList();
        }
      } catch (_) {
        // Abaikan error cache, langsung fetch dari API
      }
    }

    // 2. Ambil data dari API Odoo jika cache kosong/expired
    try {
      final rawList = await apiService.fetchAttendanceHistory(token);
      
      // Simpan data mentah terbaru ke Hive untuk cache berikutnya
      await localStorage.saveAttendanceHistory(rawList);
      
      return rawList.map((item) => AttendanceRecord.fromJson(item)).toList();
    } catch (e) {
      // 3. Fallback jika jaringan/API error: coba baca cache terakhir meskipun expired
      try {
        final cachedList = await localStorage.loadAttendanceHistory();
        if (cachedList != null) {
          return cachedList.map((item) => AttendanceRecord.fromJson(item)).toList();
        }
      } catch (_) {}
      
      rethrow;
    }
  }
}