import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance_record.dart';

/// Repository untuk mengambil data kehadiran dari Middleware sekolah.
class AttendanceRepository {
  // URL Endpoint Middleware REST API
  static const _middlewareBaseUrl = String.fromEnvironment(
    'MIDDLEWARE_URL',
    defaultValue: 'https://api-sekolah.example.com/api/v1',
  );

  final http.Client _httpClient;

  AttendanceRepository({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Mengambil riwayat kehadiran siswa dari Middleware
  Future<List<AttendanceRecord>> loadCurrentStudentHistory({
    required String userToken, // Token autentikasi/Bearer Token dari session login
  }) async {
    final url = Uri.parse('$_middlewareBaseUrl/attendance/history');

    final response = await _httpClient.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $userToken', // Kirim token user ke middleware
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      
      if (body['success'] == true && body['data'] != null) {
        final List<dynamic> dataList = body['data'];
        
        return dataList.map((item) {
          return AttendanceRecord(
            studentName: item['student_name'] ?? 'Siswa',
            kelas: item['course_name'] ?? '-',
            rombel: item['batch_name'] ?? '-',
            hadir: (item['present'] == true) ? 1 : 0,
            sakit: (item['sick'] == true) ? 1 : 0,
            izin: (item['excused'] == true) ? 1 : 0,
            alpha: (item['absent'] == true) ? 1 : 0,
            status: item['status'] ?? '',
            remark: item['remark'] ?? '-',
            date: DateTime.parse(item['attendance_date']),
          );
        }).toList();
      } else {
        throw Exception(body['message'] ?? 'Gagal memuat data dari Middleware.');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Sesi telah berakhir. Silakan login kembali.');
    } else {
      throw Exception('Gagal terhubung ke server middleware (${response.statusCode}).');
    }
  }
}