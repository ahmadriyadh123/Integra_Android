import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl;

  AuthService({required this.baseUrl});

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'username': username,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15), onTimeout: () {
            throw TimeoutException('Waktu tunggu koneksi habis');
          });

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return jsonResponse['data'] as Map<String, dynamic>;
      } else {
        final message = jsonResponse['detail'] ?? jsonResponse['message'] ?? 'Login gagal';
        throw Exception(message);
      }
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat login');
    }
  }

  /// Validasi token ke backend.
  /// Throw exception jika token invalid atau expired.
  Future<void> validateToken(String token) async {
    final url = Uri.parse('$baseUrl/auth/validate');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10), onTimeout: () {
            throw TimeoutException('Validasi token timeout');
          });

      final jsonResponse = json.decode(response.body);

      if (response.statusCode != 200 || jsonResponse['success'] != true) {
        throw Exception('Token tidak valid atau expired');
      }
    } on TimeoutException {
      // Jika timeout, tidak perlu logout (mungkin server sedang lambat)
      return;
    } on http.ClientException {
      // Network error, biarkan user tetap login dengan cache
      return;
    } catch (_) {
      throw Exception('Gagal validasi token');
    }
  }
}
