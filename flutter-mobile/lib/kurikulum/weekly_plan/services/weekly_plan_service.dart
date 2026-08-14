import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeeklyPlanService {
  final String baseUrl;

  WeeklyPlanService({required this.baseUrl});

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Ambil daftar weekly plan milik siswa
  Future<List<dynamic>> fetchWeeklyPlanList(String token) async {
    final url = Uri.parse('$baseUrl/weekly-plan/list');
    try {
      final response = await http
          .get(url, headers: _headers(token))
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('Waktu tunggu koneksi habis');
      });

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        final data = json['data'] as Map<String, dynamic>;
        return data['weekly_plans'] as List<dynamic>? ?? [];
      }
      throw Exception(
          json['detail'] ?? json['message'] ?? 'Gagal mengambil Weekly Plan');
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat mengambil Weekly Plan');
    }
  }

  /// Ambil URL PDF untuk ditampilkan di viewer
  /// Mengembalikan URL endpoint — PDF di-stream langsung oleh middleware
  String getPdfUrl(String baseUrl, int planId) {
    return '$baseUrl/weekly-plan/pdf/$planId';
  }
}
