import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/tenant_api_config.dart';

class AttendanceService {
  final String baseUrl;
  final TenantApiConfig tenantApiConfig;

  AttendanceService({required this.baseUrl, required this.tenantApiConfig});

  Future<List<dynamic>> fetchAttendanceHistory(
    String token, {
    int limit = 100,
  }) async {
    if (token.trim().isEmpty) {
      throw Exception(
        'Token login kosong. Jalankan login dan kirim AUTH_TOKEN yang valid.',
      );
    }

    final url = Uri.parse('$baseUrl/attendance/history?limit=$limit');

    try {
      final response = await http
          .get(url, headers: tenantApiConfig.headers(token: token))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Waktu tunggu koneksi habis');
            },
          );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse['data'] as List<dynamic>;
        } else {
          throw Exception(
            jsonResponse['message'] ?? 'Gagal memuat data presensi',
          );
        }
      } else {
        throw Exception(
          'Server Error ${response.statusCode}: ${response.body}',
        );
      }
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Gagal memuat data presensi');
    }
  }
}
