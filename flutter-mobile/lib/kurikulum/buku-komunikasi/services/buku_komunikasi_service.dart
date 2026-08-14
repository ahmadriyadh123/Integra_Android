import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BukuKomunikasiService {
  final String baseUrl;

  BukuKomunikasiService({required this.baseUrl});

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>?> fetchBukuKomunikasi(String token) async {
    final url = Uri.parse('$baseUrl/buku-komunikasi');
    try {
      final response = await http
          .get(url, headers: _headers(token))
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('Waktu tunggu koneksi habis');
      });

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        return json['data'] as Map<String, dynamic>?;
      }
      throw Exception(json['detail'] ?? json['message'] ?? 'Gagal mengambil Buku Komunikasi');
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat mengambil Buku Komunikasi');
    }
  }

  Future<bool> submitFeedback({
    required String token,
    required int lineId,
    required String day,
    required String feedbackText,
  }) async {
    final url = Uri.parse('$baseUrl/buku-komunikasi/feedback');
    try {
      final response = await http
          .post(
            url,
            headers: _headers(token),
            body: jsonEncode({
              'line_id': lineId,
              'day': day.toLowerCase(),
              'feedback_text': feedbackText,
            }),
          )
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('Waktu tunggu koneksi habis');
      });

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        return true;
      }
      throw Exception(json['detail'] ?? json['message'] ?? 'Gagal menyimpan feedback');
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat menyimpan feedback');
    }
  }
}
