import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/tenant_api_config.dart';
import '../models/school_model.dart';

class AuthNetworkException implements Exception {
  const AuthNetworkException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthSessionInvalidException implements Exception {
  const AuthSessionInvalidException(this.message);

  final String message;
}

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

  Future<http.Response> _get(
    Uri uri, {
    Map<String, String>? headers,
  }) =>
      (client ?? tenantApiConfig.httpClient)?.get(uri, headers: headers) ??
      http.get(uri, headers: headers);

  Future<http.Response> _post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) =>
      (client ?? tenantApiConfig.httpClient)?.post(
        uri,
        headers: headers,
        body: body,
      ) ??
      http.post(uri, headers: headers, body: body);

  Map<String, dynamic> _decodeObject(String body, String responseName) {
    final decoded = json.decode(body);
    if (decoded is! Map) {
      throw FormatException('Respons $responseName tidak valid.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<List<SchoolOption>?> loadCachedSchools() async {
    final preferences = await SharedPreferences.getInstance();
    final cacheKey = '$_schoolsCacheKeyPrefix${baseUrl.trim()}';
    final cachedSchools = preferences.getString(cacheKey);
    if (cachedSchools == null) return null;

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
      return null;
    }
  }

  Future<List<SchoolOption>> fetchSchools({bool forceRefresh = false}) async {
    final preferences = await SharedPreferences.getInstance();
    final cacheKey = '$_schoolsCacheKeyPrefix${baseUrl.trim()}';
    final cachedSchools = await loadCachedSchools();
    if (cachedSchools != null && !forceRefresh) return cachedSchools;

    if (baseUrl.trim().isEmpty) {
      throw Exception(
        'Alamat API belum dikonfigurasi. Jalankan aplikasi dengan API_BASE_URL.',
      );
    }

    try {
      final uri = Uri.parse('$baseUrl/auth/schools');
      final response = await _get(
        uri,
        headers: const {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      final jsonResponse = _decodeObject(response.body, 'daftar sekolah');

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
      final response = await _post(
        url,
        headers: tenantApiConfig.headers(),
        body: json.encode({'username': username, 'password': password}),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Waktu tunggu koneksi habis');
        },
      );

      final jsonResponse = _decodeObject(response.body, 'login');

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        final data = jsonResponse['data'];
        if (data is Map) return Map<String, dynamic>.from(data);
        throw const FormatException('Data login tidak valid.');
      } else {
        final message =
            jsonResponse['detail']?.toString() ??
            jsonResponse['message']?.toString() ??
            'Login gagal';
        throw Exception(message);
      }
    } on TimeoutException {
      throw const AuthNetworkException(
        'Koneksi ke server terlalu lama. Coba lagi.',
      );
    } on http.ClientException catch (e) {
      throw AuthNetworkException('Gagal terhubung ke server: ${e.message}');
    } on SocketException catch (e) {
      throw AuthNetworkException('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat login');
    }
  }

  /// Validasi token ke backend.
  /// Throw exception jika token invalid atau expired.
  Future<void> validateToken(String token) async {
    final url = Uri.parse('$baseUrl/auth/validate');

    final http.Response response;
    try {
      response = await _post(
        url,
        headers: tenantApiConfig.headers(token: token),
      ).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      return;
    } on http.ClientException {
      return;
    } on SocketException {
      return;
    }

    if (response.statusCode == 401) {
      var message = 'Sesi login tidak berlaku. Silakan login kembali.';
      try {
        final jsonResponse = _decodeObject(response.body, 'validasi token');
        message = jsonResponse['detail']?.toString() ?? message;
      } on FormatException {
        // Keep the actionable session-expired message for non-JSON responses.
      }
      throw AuthSessionInvalidException(message);
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final http.Response response;
    try {
      response = await _post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: tenantApiConfig.headers(),
        body: json.encode({'refresh_token': refreshToken}),
      ).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const AuthNetworkException(
        'Koneksi ke server terlalu lama. Coba lagi.',
      );
    } on http.ClientException catch (error) {
      throw AuthNetworkException('Gagal terhubung ke server: ${error.message}');
    } on SocketException catch (error) {
      throw AuthNetworkException('Gagal terhubung ke server: ${error.message}');
    }
    final decoded = _decodeObject(response.body, 'refresh token');
    final data = decoded['data'];
    if (response.statusCode == 200 &&
        decoded['success'] == true &&
        data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (response.statusCode == 403) {
      throw TenantTokenMismatchException(
        decoded['detail']?.toString() ??
            'Akun Anda tidak sesuai dengan sekolah yang dipilih. Silakan periksa konfigurasi tenant.',
      );
    }
    if (response.statusCode == 401 || response.statusCode == 400) {
      throw AuthSessionInvalidException(
        decoded['detail']?.toString() ??
            'Sesi login telah berakhir. Silakan login kembali.',
      );
    }
    throw Exception(
      decoded['detail']?.toString() ?? 'Gagal memperbarui sesi login.',
    );
  }

  Future<void> revokeRefreshToken(String refreshToken) async {
    await _post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: tenantApiConfig.headers(),
      body: json.encode({'refresh_token': refreshToken}),
    );
  }

  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/auth/change-password');

    try {
      final response = await _post(
        url,
        headers: tenantApiConfig.headers(token: token),
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      )
          .timeout(const Duration(seconds: 15));

      final jsonResponse = _decodeObject(response.body, 'ganti password');
      if (response.statusCode != 200 || jsonResponse['success'] != true) {
        throw Exception(
          jsonResponse['detail'] ??
              jsonResponse['message'] ??
              'Gagal mengganti password',
        );
      }
    } on TimeoutException {
      throw const AuthNetworkException(
        'Koneksi ke server terlalu lama. Perubahan menunggu sinkronisasi.',
      );
    } on http.ClientException catch (e) {
      throw AuthNetworkException(
        'Gagal terhubung ke server: ${e.message}',
      );
    } on SocketException catch (e) {
      throw AuthNetworkException(
        'Gagal terhubung ke server: ${e.message}',
      );
    }
  }
}
