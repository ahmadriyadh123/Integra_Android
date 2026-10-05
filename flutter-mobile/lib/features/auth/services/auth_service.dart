import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/tenant_api_config.dart';
import '../models/school_model.dart';

class AuthService {
  static const _schoolsCacheKeyPrefix = 'school_options_cache_';

  final String baseUrl;
  final TenantApiConfig tenantApiConfig;
  final http.Client? client;

  AuthService({
    required this.baseUrl,
    required this.tenantApiConfig,
    this.client,
  });

  Future<List<SchoolOption>> fetchSchools() async {
    final preferences = await SharedPreferences.getInstance();
    final cacheKey = '$_schoolsCacheKeyPrefix${baseUrl.trim()}';
    final cachedSchools = preferences.getString(cacheKey);
    if (cachedSchools != null) {
      try {
        final decoded = json.decode(cachedSchools);
        if (decoded is! List) {
          throw const FormatException('Format daftar sekolah tidak valid');
        }
        return decoded
            .map((school) {
              if (school is! Map<String, dynamic>) {
                throw const FormatException('Data sekolah tidak valid');
              }
              return SchoolOption.fromJson(school);
            })
            .toList(growable: false);
      } on FormatException {
        await preferences.remove(cacheKey);
      }
    }

    if (baseUrl.trim().isEmpty) {
      throw Exception(
        'Alamat API belum dikonfigurasi. Jalankan aplikasi dengan API_BASE_URL.',
      );
    }

    try {
      final uri = Uri.parse('$baseUrl/auth/schools');
      final response = await (client == null
              ? http.get(
                  uri,
                  headers: const {'Content-Type': 'application/json'},
                )
              : client!.get(
                  uri,
                  headers: const {'Content-Type': 'application/json'},
                ))
          .timeout(const Duration(seconds: 15));
      final jsonResponse = json.decode(response.body);

      if (response.statusCode != 200 || jsonResponse['success'] != true) {
        throw Exception(
          jsonResponse['detail'] ??
              jsonResponse['message'] ??
              'Gagal mengambil daftar sekolah',
        );
      }

      final schools = jsonResponse['data'];
      if (schools is! List) {
        throw const FormatException('Format daftar sekolah tidak valid');
      }

      final parsedSchools = schools
          .map((school) {
            if (school is! Map<String, dynamic>) {
              throw const FormatException('Data sekolah tidak valid');
            }
            return SchoolOption.fromJson(school);
          })
          .toList(growable: false);
      await preferences.setString(
        cacheKey,
        json.encode(parsedSchools.map((school) => school.toJson()).toList()),
      );
      return parsedSchools;
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (error) {
      throw Exception('Gagal terhubung ke server: ${error.message}');
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    if (baseUrl.trim().isEmpty) {
      throw Exception(
        'Alamat API belum dikonfigurasi. Jalankan aplikasi dengan API_BASE_URL.',
      );
    }
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      final response = await http
          .post(
            url,
            headers: tenantApiConfig.headers(),
            body: json.encode({'username': username, 'password': password}),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Waktu tunggu koneksi habis');
            },
          );

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return jsonResponse['data'] as Map<String, dynamic>;
      } else {
        final message =
            jsonResponse['detail'] ?? jsonResponse['message'] ?? 'Login gagal';
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
          .post(url, headers: tenantApiConfig.headers(token: token))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Validasi token timeout');
            },
          );

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

  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/auth/change-password');

    try {
      final response = await http
          .post(
            url,
            headers: tenantApiConfig.headers(token: token),
            body: json.encode({
              'current_password': currentPassword,
              'new_password': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final jsonResponse = json.decode(response.body);
      if (response.statusCode != 200 || jsonResponse['success'] != true) {
        throw Exception(
          jsonResponse['detail'] ??
              jsonResponse['message'] ??
              'Gagal mengganti password',
        );
      }
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat mengganti password');
    }
  }
}
