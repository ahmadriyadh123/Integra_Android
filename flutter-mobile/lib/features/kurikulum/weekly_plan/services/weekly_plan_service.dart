import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeeklyPlanService {
  final String baseUrl;

  WeeklyPlanService({required this.baseUrl});

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Future<List<dynamic>> fetchWeeklyPlanList(String token) async {
    final url = Uri.parse('$baseUrl/weekly-plan/list');
    try {
      final response = await http
          .get(url, headers: _headers(token))
          .timeout(const Duration(seconds: 15));
      final decoded = jsonDecode(response.body);
      if (decoded is Map && response.statusCode == 200 && decoded['success'] == true) {
        final data = decoded['data'];
        if (data is Map && data['weekly_plans'] is List) {
          return data['weekly_plans'];
        }
        return [];
      }
      throw Exception(decoded['detail'] ?? decoded['message'] ?? 'Gagal mengambil Weekly Plan');
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  /// Ambil JSON Detail dari Backend
  Future<Map<String, dynamic>> fetchWeeklyPlanDetail(int planId, String token) async {
    final url = Uri.parse('$baseUrl/weekly-plan/detail/$planId');
    try {
      final response = await http
          .get(url, headers: _headers(token))
          .timeout(const Duration(seconds: 15));
      final decoded = jsonDecode(response.body);
      if (decoded is Map && response.statusCode == 200 && decoded['success'] == true) {
        if (decoded['data'] is Map) {
          return Map<String, dynamic>.from(decoded['data']);
        }
      }
      throw Exception(decoded['detail'] ?? decoded['message'] ?? 'Detail tidak ditemukan');
    } catch (e) {
      throw Exception('Gagal mengambil detail data: $e');
    }
  }

  Future<Uint8List> fetchWeeklyPlanPdfFile(int planId, String token) async {
    final url = Uri.parse('$baseUrl/weekly-plan/pdf/$planId');
    try {
      final response = await http
          .get(url, headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      
      throw Exception('Gagal mengunduh dokumen PDF (Status: ${response.statusCode})');
    } catch (e) {
      throw Exception('Gagal terhubung ke server untuk mengambil PDF: $e');
    }
  }
}