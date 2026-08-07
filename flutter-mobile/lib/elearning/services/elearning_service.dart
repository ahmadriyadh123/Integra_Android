import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ElearningService {
  final String baseUrl;

  ElearningService({required this.baseUrl});

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<dynamic>> fetchCourses(String token) async {
    final url = Uri.parse('$baseUrl/elearning/courses');
    try {
      final response = await http
          .get(url, headers: _headers(token))
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('Waktu tunggu koneksi habis');
      });

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        return json['data'] as List<dynamic>;
      }
      throw Exception(json['detail'] ?? json['message'] ?? 'Gagal mengambil kursus');
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat mengambil data kursus');
    }
  }

  Future<Map<String, dynamic>> fetchCourseDetail(
      String token, int courseId) async {
    final url = Uri.parse('$baseUrl/elearning/courses/$courseId');
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
      throw Exception(json['detail'] ?? json['message'] ?? 'Gagal mengambil detail kursus');
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat mengambil detail kursus');
    }
  }
}
