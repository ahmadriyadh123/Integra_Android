import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/services/tenant_api_config.dart';
import 'package:http/http.dart' as http;

class ElearningService {
  final String baseUrl;
  final TenantApiConfig tenantApiConfig;
  final http.Client? httpClient;

  ElearningService({
    required this.baseUrl,
    required this.tenantApiConfig,
    this.httpClient,
  });

  Map<String, String> _headers(String token) =>
      tenantApiConfig.headers(token: token);

  Future<http.Response> _send(Future<http.Response> request) async {
    try {
      return await request.timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Waktu tunggu koneksi habis'),
      );
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    }
  }

  Future<http.Response> _get(Uri uri, String token) {
    final headers = _headers(token);
    final client = httpClient;
    final configuredClient = tenantApiConfig.httpClient;
    return _send(
      client != null
          ? client.get(uri, headers: headers)
          : configuredClient != null
          ? configuredClient.get(uri, headers: headers)
          : http.get(uri, headers: headers),
    );
  }

  Future<http.Response> _post(
    Uri uri,
    String token, {
    required Object body,
  }) {
    final headers = _headers(token);
    final client = httpClient;
    final configuredClient = tenantApiConfig.httpClient;
    final encodedBody = jsonEncode(body);
    return _send(
      client != null
          ? client.post(uri, headers: headers, body: encodedBody)
          : configuredClient != null
          ? configuredClient.post(uri, headers: headers, body: encodedBody)
          : http.post(uri, headers: headers, body: encodedBody),
    );
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded.keys.any((key) => key is! String)) {
      throw const FormatException('Respons E-Learning harus berupa objek JSON');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Map<String, dynamic> _successfulBody(
    http.Response response, {
    required String fallbackMessage,
  }) {
    final decoded = _decodeObject(response);
    if (response.statusCode == 200 && decoded['success'] == true) {
      return decoded;
    }
    final detail = decoded['detail'];
    final message = decoded['message'];
    final error = detail is String && detail.isNotEmpty
        ? detail
        : message is String && message.isNotEmpty
        ? message
        : fallbackMessage;
    throw Exception(error);
  }

  Map<String, dynamic> _objectValue(dynamic value, String errorMessage) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw FormatException(errorMessage);
    }
    return Map<String, dynamic>.from(value);
  }

  List<dynamic> _listValue(dynamic value, String errorMessage) {
    if (value is! List) throw FormatException(errorMessage);
    return value;
  }

  Future<Map<String, dynamic>> syncCourses(
    String token, {
    String? cursor,
  }) async {
    final uri = Uri.parse('$baseUrl/elearning/courses/sync').replace(
      queryParameters: cursor == null ? null : {'cursor': cursor},
    );
    final response = await _get(uri, token);
    final decoded = _successfulBody(
      response,
      fallbackMessage: 'Gagal menyinkronkan kursus',
    );
    return _objectValue(
      decoded['data'],
      'Format sinkronisasi kursus tidak valid',
    );
  }

  Future<List<dynamic>> fetchCourses(String token) async {
    final response = await _get(
      Uri.parse('$baseUrl/elearning/courses'),
      token,
    );
    final decoded = _successfulBody(
      response,
      fallbackMessage: 'Gagal mengambil kursus',
    );
    return _listValue(decoded['data'], 'Daftar kursus tidak valid');
  }

  Future<Map<String, dynamic>> fetchCourseDetail(
    String token,
    int courseId,
  ) async {
    final response = await _get(
      Uri.parse('$baseUrl/elearning/courses/$courseId'),
      token,
    );
    final decoded = _successfulBody(
      response,
      fallbackMessage: 'Gagal mengambil detail kursus',
    );
    return _objectValue(decoded['data'], 'Detail kursus tidak valid');
  }

  Future<String> fetchSlideContent(String token, int slideId) async {
    final response = await _get(
      Uri.parse('$baseUrl/elearning/content/$slideId'),
      token,
    );
    final decoded = _successfulBody(
      response,
      fallbackMessage: 'Gagal mengambil konten materi',
    );
    final contentUrl = decoded['url'];
    if (contentUrl is String && contentUrl.isNotEmpty) return contentUrl;
    throw const FormatException('URL konten materi tidak valid');
  }

  Future<void> markSlideCompleted(
    String token,
    int courseId,
    int slideId, {
    required String source,
    String? completionStatus,
  }) async {
    final response = await _post(
      Uri.parse(
        '$baseUrl/elearning/courses/$courseId/slides/$slideId/progress',
      ),
      token,
      body: {
        'source': source,
        'completion_status': ?completionStatus,
      },
    );
    _successfulBody(
      response,
      fallbackMessage: 'Gagal menyimpan progres materi',
    );
  }

  Future<List<dynamic>> fetchCourseMessages(
    String token,
    int courseId,
  ) async {
    final response = await _get(
      Uri.parse('$baseUrl/elearning/courses/$courseId/messages'),
      token,
    );
    final decoded = _successfulBody(
      response,
      fallbackMessage: 'Gagal mengambil diskusi kursus',
    );
    return _listValue(decoded['data'], 'Daftar diskusi kursus tidak valid');
  }

  Future<void> sendCourseMessage(
    String token,
    int courseId,
    String body,
  ) async {
    final response = await _post(
      Uri.parse('$baseUrl/elearning/courses/$courseId/messages'),
      token,
      body: {'body': body},
    );
    _successfulBody(
      response,
      fallbackMessage: 'Gagal mengirim pesan',
    );
  }
}
