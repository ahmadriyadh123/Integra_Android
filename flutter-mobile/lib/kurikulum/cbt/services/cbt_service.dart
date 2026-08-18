import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CbtService {
  final String baseUrl;

  CbtService({required this.baseUrl});

  /// Ambil daftar jadwal ujian CBT dari middleware
  Future<Map<String, dynamic>> fetchCbtSchedules(String token) async {
    if (token.trim().isEmpty) {
      throw Exception('Token login kosong. Jalankan login dan kirim AUTH_TOKEN yang valid.');
    }

    final url = Uri.parse('$baseUrl/cbt/schedules');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15), onTimeout: () {
            throw TimeoutException('Waktu tunggu koneksi habis');
          });

      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return jsonResponse['data'] as Map<String, dynamic>;
      } else {
        final message = jsonResponse['detail'] ?? jsonResponse['message'] ?? 'Gagal mengambil data CBT';
        throw Exception(message);
      }
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat mengambil data CBT');
    }
  }
}



