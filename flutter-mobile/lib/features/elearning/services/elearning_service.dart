import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/tenant_api_config.dart';

class ElearningService {
  final String baseUrl;
  final TenantApiConfig tenantApiConfig;

  ElearningService({required this.baseUrl, required this.tenantApiConfig});

  Map<String, String> _headers(String token) =>
      tenantApiConfig.headers(token: token);

  Future<List<dynamic>> fetchCourses(String token) async {
    // Semua request e-learning membawa token session yang sama.
    final url = Uri.parse('$baseUrl/elearning/courses');
    try {
      final response = await http
          .get(url, headers: _headers(token))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Waktu tunggu koneksi habis');
            },
          );

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        return json['data'] as List<dynamic>;
      }
      throw Exception(
        json['detail'] ?? json['message'] ?? 'Gagal mengambil kursus',
      );
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
    String token,
    int courseId,
  ) async {
    final url = Uri.parse('$baseUrl/elearning/courses/$courseId');
    try {
      final response = await http
          .get(url, headers: _headers(token))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Waktu tunggu koneksi habis');
            },
          );

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        return json['data'] as Map<String, dynamic>;
      }
      throw Exception(
        json['detail'] ?? json['message'] ?? 'Gagal mengambil detail kursus',
      );
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat mengambil detail kursus');
    }
  }

  Future<String> fetchSlideContent(String token, int slideId) async {
    final url = Uri.parse('$baseUrl/elearning/content/$slideId');
    final response = await http
        .get(url, headers: _headers(token))
        .timeout(const Duration(seconds: 15));

    final json = jsonDecode(response.body);
    if (response.statusCode == 200 && json['success'] == true) {
      final contentUrl = json['url'] as String?;
      if (contentUrl != null && contentUrl.isNotEmpty) return contentUrl;
    }
    throw Exception(
      json['detail'] ?? json['message'] ?? 'Gagal mengambil konten materi',
    );
  }

  Future<void> markSlideCompleted(
    String token,
    int courseId,
    int slideId, {
    required String source,
    String? completionStatus,
  }) async {
    final url = Uri.parse(
      '$baseUrl/elearning/courses/$courseId/slides/$slideId/progress',
    );
    final response = await http
        .post(
          url,
          headers: _headers(token),
          body: jsonEncode({
            'source': source,
            if (completionStatus != null)
              'completion_status': completionStatus,
          }),
        )
        .timeout(const Duration(seconds: 15));
    final json = jsonDecode(response.body);
    if (response.statusCode == 200 && json['success'] == true) return;
    throw Exception(
      json['detail'] ?? json['message'] ?? 'Gagal menyimpan progres materi',
    );
  }

  Future<List<dynamic>> fetchCourseMessages(
    String token,
    int courseId,
  ) async {
    final url = Uri.parse('$baseUrl/elearning/courses/$courseId/messages');
    final response = await http
        .get(url, headers: _headers(token))
        .timeout(const Duration(seconds: 15));
    final json = jsonDecode(response.body);
    if (response.statusCode == 200 && json['success'] == true) {
      return json['data'] as List<dynamic>;
    }
    throw Exception(
      json['detail'] ?? json['message'] ?? 'Gagal mengambil diskusi kursus',
    );
  }

  Future<void> sendCourseMessage(
    String token,
    int courseId,
    String body,
  ) async {
    final url = Uri.parse('$baseUrl/elearning/courses/$courseId/messages');
    final response = await http
        .post(
          url,
          headers: _headers(token),
          body: jsonEncode({'body': body}),
        )
        .timeout(const Duration(seconds: 15));
    final json = jsonDecode(response.body);
    if (response.statusCode == 200 && json['success'] == true) return;
    throw Exception(
      json['detail'] ?? json['message'] ?? 'Gagal mengirim pesan',
    );
  }
}
