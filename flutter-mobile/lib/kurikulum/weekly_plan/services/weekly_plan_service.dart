import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeeklyPlanService {
  final String baseUrl;

  WeeklyPlanService({required this.baseUrl});

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
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

      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final json = Map<String, dynamic>.from(decoded);
        if (response.statusCode == 200 && json['success'] == true) {
          final data = json['data'];
          if (data is Map) {
            final dataMap = Map<String, dynamic>.from(data);
            final plans = dataMap['weekly_plans'];
            if (plans is List) {
              return plans;
            }
          }
          return [];
        }
        throw Exception(
            json['detail'] ?? json['message'] ?? 'Gagal mengambil Weekly Plan');
      }
      throw Exception('Format respon server tidak valid');
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat mengambil Weekly Plan: $e');
    }
  }


  /// Ambil URL PDF untuk ditampilkan di viewer
  /// Mengembalikan URL endpoint — PDF di-stream langsung oleh middleware
  String getPdfUrl(String baseUrl, int planId) {
    return '$baseUrl/weekly-plan/pdf/$planId';
  }
}
