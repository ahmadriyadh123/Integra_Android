import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RaporService {
  final String baseUrl;

  RaporService({required this.baseUrl});

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<dynamic>> fetchReportList(String token) async {
    final url = Uri.parse('$baseUrl/e-rapor/list');
    try {
      final response = await http
          .get(url, headers: _headers(token))
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('Waktu tunggu koneksi habis');
      });

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        return json['data'] as List<dynamic>? ?? [];
      }
      throw Exception(json['detail'] ?? json['message'] ?? 'Gagal mengambil daftar E-Rapor');
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat mengambil daftar E-Rapor');
    }
  }

  Future<Map<String, dynamic>> fetchReportDetail(String token, int raporId) async {
    final url = Uri.parse('$baseUrl/e-rapor/$raporId');
    try {
      final response = await http
          .get(url, headers: _headers(token))
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('Waktu tunggu koneksi habis');
      });

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        return json['data'] as Map<String, dynamic>;
      }
      throw Exception(json['detail'] ?? json['message'] ?? 'Gagal mengambil detail E-Rapor');
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat mengambil detail E-Rapor');
    }
  }
}


