import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_application_1/config/api/tenant_api_config.dart';
import 'package:http/http.dart' as http;

class WeeklyPlanService {
  final String baseUrl;
  final TenantApiConfig tenantApiConfig;
  final http.Client? httpClient;

  WeeklyPlanService({
    required this.baseUrl,
    required this.tenantApiConfig,
    this.httpClient,
  });

  Map<String, String> _headers(String token) =>
      tenantApiConfig.headers(token: token);

  Future<http.Response> _get(Uri uri, String token) async {
    try {
      final client = httpClient;
      final configuredClient = tenantApiConfig.httpClient;
      return await (client != null
              ? client.get(uri, headers: _headers(token))
              : configuredClient != null
              ? configuredClient.get(uri, headers: _headers(token))
              : http.get(uri, headers: _headers(token)))
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (error) {
      throw Exception('Gagal terhubung ke server: ${error.message}');
    }
  }

  Map<String, dynamic> _decodeObject(String body, String errorMessage) {
    final decoded = jsonDecode(body);
    if (decoded is! Map || decoded.keys.any((key) => key is! String)) {
      throw FormatException(errorMessage);
    }
    return Map<String, dynamic>.from(decoded);
  }

  Map<String, dynamic> _successfulResponse(
    http.Response response, {
    required String fallbackMessage,
  }) {
    final decoded = _decodeObject(
      response.body,
      'Respons Weekly Plan tidak valid.',
    );
    if (response.statusCode == 200 && decoded['success'] == true) {
      return decoded;
    }
    final detail = decoded['detail'];
    final message = decoded['message'];
    throw Exception(
      detail is String && detail.isNotEmpty
          ? detail
          : message is String && message.isNotEmpty
          ? message
          : '$fallbackMessage (Status: ${response.statusCode})',
    );
  }

  Future<Map<String, dynamic>> syncWeeklyPlanList(
    String token, {
    String? cursor,
  }) async {
    final query = <String, String>{};
    if (cursor != null) query['cursor'] = cursor;
    final uri = Uri.parse(
      '$baseUrl/weekly-plan/list/sync',
    ).replace(queryParameters: query);
    final response = await _get(uri, token);
    final decoded = _successfulResponse(
      response,
      fallbackMessage: 'Gagal menyinkronkan Weekly Plan',
    );
    final data = decoded['data'];
    if (data is! Map || data.keys.any((key) => key is! String)) {
      throw const FormatException(
        'Data sinkronisasi Weekly Plan tidak valid.',
      );
    }
    return Map<String, dynamic>.from(data);
  }

  Future<List<dynamic>> fetchWeeklyPlanList(String token) async {
    final response = await _get(
      Uri.parse('$baseUrl/weekly-plan/list'),
      token,
    );
    final decoded = _successfulResponse(
      response,
      fallbackMessage: 'Gagal mengambil Weekly Plan',
    );
    final data = decoded['data'];
    if (data is! Map ||
        data.keys.any((key) => key is! String) ||
        data['weekly_plans'] is! List) {
      throw const FormatException(
        'Daftar Weekly Plan pada respons tidak valid.',
      );
    }
    return data['weekly_plans'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> fetchWeeklyPlanDetail(
    int planId,
    String token,
  ) async {
    final response = await _get(
      Uri.parse('$baseUrl/weekly-plan/detail/$planId'),
      token,
    );
    final decoded = _successfulResponse(
      response,
      fallbackMessage: 'Detail Weekly Plan tidak ditemukan',
    );
    final data = decoded['data'];
    if (data is! Map || data.keys.any((key) => key is! String)) {
      throw const FormatException('Detail Weekly Plan tidak valid.');
    }
    return Map<String, dynamic>.from(data);
  }

  Future<Uint8List> fetchWeeklyPlanPdfFile(int planId, String token) async {
    final response = await _get(
      Uri.parse('$baseUrl/weekly-plan/pdf/$planId'),
      token,
    );
    if (response.statusCode == 200) return response.bodyBytes;

    String? message;
    try {
      final decoded = _decodeObject(
        response.body,
        'Respons error PDF Weekly Plan tidak valid.',
      );
      final detail = decoded['detail'];
      final responseMessage = decoded['message'];
      message = detail is String && detail.isNotEmpty
          ? detail
          : responseMessage is String && responseMessage.isNotEmpty
          ? responseMessage
          : null;
    } on FormatException {
      message = null;
    }
    throw Exception(
      message ??
          'Gagal mengunduh dokumen PDF (Status: ${response.statusCode})',
    );
  }
}
