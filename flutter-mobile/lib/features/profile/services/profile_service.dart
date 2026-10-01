import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ProfileService {
  final String baseUrl;
  final http.Client? _client;
  final Map<String, Uint8List> _profileImageCache = {};
  final Map<String, Future<Uint8List>> _pendingProfileImages = {};

  ProfileService({required this.baseUrl, http.Client? client}) : _client = client;

  Future<Map<String, dynamic>> getMyProfile(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/profile/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

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

  Future<Uint8List> getProfileImage(String token, int partnerId) {
    final cacheKey = '$partnerId:$token';
    final cachedImage = _profileImageCache[cacheKey];
    if (cachedImage != null) return Future.value(cachedImage);

    return _pendingProfileImages.putIfAbsent(cacheKey, () async {
      try {
        final uri = Uri.parse('$baseUrl/profile/image/$partnerId');
        final headers = {'Authorization': 'Bearer $token'};
        final request = _client?.get(uri, headers: headers) ??
            http.get(uri, headers: headers);
        final response = await request.timeout(const Duration(seconds: 15));

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          _profileImageCache[cacheKey] = response.bodyBytes;
          return response.bodyBytes;
        }
        throw Exception('Foto profil tidak ditemukan');
      } finally {
        _pendingProfileImages.remove(cacheKey);
      }
    });
  }
}
