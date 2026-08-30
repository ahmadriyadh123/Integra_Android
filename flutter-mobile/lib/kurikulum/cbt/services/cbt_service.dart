import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CbtService {
  final String baseUrl;

  CbtService({required this.baseUrl});

  /// Ambil daftar jadwal ujian CBT dari middleware
  Future<Map<String, dynamic>> fetchCbtSchedules(String token) async {
    if (token.trim().isEmpty) {
      throw Exception(
        'Token login kosong. Jalankan login dan kirim AUTH_TOKEN yang valid.',
      );
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
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Waktu tunggu koneksi habis');
            },
          );

      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return jsonResponse['data'] as Map<String, dynamic>;
      } else {
        final message =
            jsonResponse['detail'] ??
            jsonResponse['message'] ??
            'Gagal mengambil data CBT';
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

  /// Verifikasi token ujian ke middleware/Odoo
  Future<bool> verifyExamToken(
    String token,
    int jadwalId,
    String tokenInput,
  ) async {
    final url = Uri.parse('$baseUrl/cbt/verify-token');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'jadwal_ujian_id': jadwalId,
              'token_input': tokenInput.trim(),
            }),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Waktu tunggu koneksi habis');
            },
          );

      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        if (jsonResponse['success'] == true && jsonResponse['data'] == true) {
          return true;
        }
        final message =
            jsonResponse['message'] ??
            'Token ujian tidak valid. Periksa kembali token dari pengawas.';
        throw Exception(message);
      } else {
        final message =
            jsonResponse['detail'] ??
            jsonResponse['message'] ??
            'Verifikasi token gagal';
        throw Exception(message);
      }
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat verifikasi token');
    }
  }

  /// Ambil daftar soal ujian berdasarkan jadwal_id
  Future<Map<String, dynamic>> fetchExamQuestions(
    String token,
    int jadwalId,
  ) async {
    final url = Uri.parse('$baseUrl/cbt/questions/$jadwalId');
    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Waktu tunggu koneksi habis');
            },
          );

      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return jsonResponse['data'] as Map<String, dynamic>;
      } else {
        final message =
            jsonResponse['detail'] ??
            jsonResponse['message'] ??
            'Gagal mengambil soal ujian';
        throw Exception(message);
      }
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat mengambil soal ujian');
    }
  }

  /// Submit jawaban ujian
  Future<Map<String, dynamic>> submitExam(
    String token,
    int jadwalId,
    List<Map<String, dynamic>> answers,
    String? waktuMulai,
  ) async {
    final url = Uri.parse('$baseUrl/cbt/submit');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'jadwal_ujian_id': jadwalId,
              'answers': answers,
              if (waktuMulai != null) 'waktu_mulai': waktuMulai,
            }),
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException('Waktu tunggu koneksi habis');
            },
          );

      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return jsonResponse['data'] as Map<String, dynamic>;
      } else {
        final message =
            jsonResponse['detail'] ??
            jsonResponse['message'] ??
            'Gagal menyimpan jawaban ujian';
        throw Exception(message);
      }
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat mengirim jawaban ujian');
    }
  }
}
