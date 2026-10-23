import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/config/api/tenant_api_config.dart';

class BukuKomunikasiService {
  final String baseUrl;
  final TenantApiConfig tenantApiConfig;
  final http.Client? httpClient;

  BukuKomunikasiService({
    required this.baseUrl,
    required this.tenantApiConfig,
    this.httpClient,
  });

  Map<String, String> _headers(String token) =>
      tenantApiConfig.headers(token: token);

  /// Pilih HTTP client yang tepat.
  ///
  /// Prioritas:
  /// 1. [tenantApiConfig.httpClient] — AuthenticatedHttpClient yang menangani
  ///    refresh token 401 secara otomatis. Digunakan selama tersedia.
  /// 2. [httpClient] — override eksplisit (umumnya hanya untuk unit test).
  /// 3. Fallback global `http.get/post` jika keduanya null.
  http.Client? get _effectiveClient =>
      tenantApiConfig.httpClient ?? httpClient;

  Future<http.Response> _get(Uri uri, String token) async {
    try {
      final client = _effectiveClient;
      return await (client != null
              ? client.get(uri, headers: _headers(token))
              : http.get(uri, headers: _headers(token)))
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    }
  }

  Future<http.Response> _post(Uri uri, String token, String body) async {
    try {
      final client = _effectiveClient;
      return await (client != null
              ? client.post(uri, headers: _headers(token), body: body)
              : http.post(uri, headers: _headers(token), body: body))
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    }
  }

  Future<Map<String, dynamic>?> fetchBukuKomunikasi(String token) async {
    final url = Uri.parse('$baseUrl/buku-komunikasi');
    try {
      final response = await _get(url, token);
      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        return json['data'] as Map<String, dynamic>?;
      }
      throw Exception(
        json['detail'] ?? json['message'] ?? 'Gagal mengambil Buku Komunikasi',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat mengambil Buku Komunikasi');
    }
  }

  /// Delta sync — hanya kirim cursor, terima data yang berubah.
  Future<Map<String, dynamic>> syncBukuKomunikasi(
    String token, {
    String? cursor,
  }) async {
    final queryParams = <String, String>{};
    if (cursor != null) queryParams['cursor'] = cursor;

    final url = Uri.parse('$baseUrl/buku-komunikasi/sync')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    try {
      final response = await _get(url, token);
      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        return json['data'] as Map<String, dynamic>;
      }
      throw Exception(
        json['detail'] ?? json['message'] ?? 'Gagal sinkronisasi Buku Komunikasi',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat sinkronisasi Buku Komunikasi');
    }
  }

  Future<bool> submitDailyNote({
    required String token,
    required int lineId,
    required String day,
    required String noteText,
    String? month,
    int? week,
  }) async {
    final url = Uri.parse('$baseUrl/buku-komunikasi/note');
    try {
      final body = jsonEncode({
        'line_id': lineId,
        'day': day.toLowerCase(),
        'note_text': noteText,
        'month': month,
        'week': week,
      });
      final response = await _post(url, token, body);
      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        return true;
      }
      throw Exception(
        json['detail'] ?? json['message'] ?? 'Gagal menyimpan catatan',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat menyimpan catatan');
    }
  }
}
