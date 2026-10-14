import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/tenant_api_config.dart';

class RaporService {
  final String baseUrl;
  final TenantApiConfig tenantApiConfig;

  RaporService({required this.baseUrl, required this.tenantApiConfig});

  Map<String, String> _headers(String token) =>
      tenantApiConfig.headers(token: token);

  Future<List<dynamic>> fetchReportList(String token) async {
    final url = Uri.parse('$baseUrl/e-rapor/list');
    try {
      final response = await (tenantApiConfig.httpClient?.get(
                url,
                headers: _headers(token),
              ) ??
              http.get(url, headers: _headers(token)))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Waktu tunggu koneksi habis');
            },
          );

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        return json['data'] as List<dynamic>? ?? [];
      }
      throw Exception(
        json['detail'] ?? json['message'] ?? 'Gagal mengambil daftar E-Rapor',
      );
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat mengambil daftar E-Rapor');
    }
  }

  Future<Map<String, dynamic>> syncReportList(
    String token, {
    String? cursor,
  }) async {
    final query = <String, String>{};
    if (cursor != null) query['cursor'] = cursor;
    final url = Uri.parse('$baseUrl/e-rapor/list/sync').replace(
      queryParameters: query,
    );
    final response = await (tenantApiConfig.httpClient?.get(
              url,
              headers: _headers(token),
            ) ??
            http.get(url, headers: _headers(token)))
        .timeout(const Duration(seconds: 15));
    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 &&
        decoded is Map &&
        decoded['success'] == true &&
        decoded['data'] is Map) {
      return Map<String, dynamic>.from(decoded['data']);
    }
    throw Exception(
      decoded is Map
          ? decoded['detail'] ?? 'Gagal menyinkronkan daftar E-Rapor'
          : 'Respons sinkronisasi daftar E-Rapor tidak valid.',
    );
  }

  Future<Map<String, dynamic>> fetchReportDetail(
    String token,
    int raporId,
  ) async {
    final url = Uri.parse('$baseUrl/e-rapor/$raporId');
    try {
      final response = await (tenantApiConfig.httpClient?.get(
                url,
                headers: _headers(token),
              ) ??
              http.get(url, headers: _headers(token)))
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
        json['detail'] ?? json['message'] ?? 'Gagal mengambil detail E-Rapor',
      );
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat mengambil detail E-Rapor');
    }
  }

  Future<Uint8List> fetchReportPdf(String token, int raporId) async {
    final url = Uri.parse('$baseUrl/e-rapor/pdf/$raporId');
    final response = await (tenantApiConfig.httpClient?.get(
              url,
              headers: _headers(token),
            ) ??
            http.get(url, headers: _headers(token)))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      String? responseDetail;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final detail = decoded['detail'] ?? decoded['message'];
          if (detail is String && detail.isNotEmpty) {
            responseDetail = detail;
          }
        }
      } on FormatException {
        responseDetail = null;
      }
      throw Exception(
        responseDetail ??
            'Gagal mengunduh PDF E-Rapor (status ${response.statusCode}).',
      );
    }
    if (response.bodyBytes.isEmpty) {
      throw const FormatException('Server mengirim PDF E-Rapor kosong.');
    }
    return response.bodyBytes;
  }
}
