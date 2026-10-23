import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/config/api/tenant_api_config.dart';

class TagihanService {
  final String baseUrl;
  final TenantApiConfig tenantApiConfig;

  TagihanService({required this.baseUrl, required this.tenantApiConfig});

  http.Client get _client =>
      tenantApiConfig.httpClient ?? http.Client();

  Map<String, String> _headers(String token) =>
      tenantApiConfig.headers(token: token);

  Future<Map<String, dynamic>> fetchTagihan(
    String token, {
    String? paymentState,
  }) async {
    final queryParams = <String, String>{};
    if (paymentState != null) queryParams['payment_state'] = paymentState;

    final url = Uri.parse('$baseUrl/tagihan/summary')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    try {
      final response = await _client
          .get(url, headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      final jsonResponse = json.decode(response.body);
      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return jsonResponse['data'] as Map<String, dynamic>;
      }
      throw Exception(
        jsonResponse['detail'] ?? jsonResponse['message'] ?? 'Gagal mengambil data tagihan',
      );
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat mengambil data tagihan');
    }
  }

  /// Delta sync — hanya kirim cursor, terima data yang berubah.
  Future<Map<String, dynamic>> syncTagihan(
    String token, {
    String? cursor,
  }) async {
    final queryParams = <String, String>{};
    if (cursor != null) queryParams['cursor'] = cursor;

    final url = Uri.parse('$baseUrl/tagihan/sync')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    try {
      final response = await _client
          .get(url, headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      final jsonResponse = json.decode(response.body);
      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return jsonResponse['data'] as Map<String, dynamic>;
      }
      throw Exception(
        jsonResponse['detail'] ?? jsonResponse['message'] ?? 'Gagal sinkronisasi tagihan',
      );
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat sinkronisasi tagihan');
    }
  }
}
