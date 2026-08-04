import '../models/attendance_record.dart';
import '../services/attendance_service.dart';

class AttendanceRepository {
  final AttendanceService apiService;

  AttendanceRepository({required this.apiService});

  Future<List<AttendanceRecord>> getAttendanceHistory(String token) async {
    try {
      final rawList = await apiService.fetchAttendanceHistory(token);
      return rawList.map((item) => AttendanceRecord.fromJson(item)).toList();
    } catch (e) {
      rethrow;
    }
  }
}