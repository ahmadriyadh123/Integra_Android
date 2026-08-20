import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ProfileService {
  final String baseUrl;

  ProfileService({required this.baseUrl});

  Future<Map<String, dynamic>> getMyProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        final data = jsonResponse['data'] as Map<String, dynamic>?;
        final profile = data?['profile'] as Map<String, dynamic>?;
        if (profile != null) return profile;
      }

      throw Exception(
        jsonResponse['detail'] ??
            jsonResponse['message'] ??
            'Data profil tidak ditemukan',
      );
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat mengambil profil');
    }
  }
}
