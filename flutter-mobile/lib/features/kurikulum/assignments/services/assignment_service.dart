import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/tenant_api_config.dart';

class AssignmentAlreadySubmittedException implements Exception {
  const AssignmentAlreadySubmittedException();

  @override
  String toString() => 'Tugas ini sudah dikumpulkan sebelumnya.';
}

class AssignmentService {
  final String baseUrl;
  final TenantApiConfig tenantApiConfig;

  AssignmentService({required this.baseUrl, required this.tenantApiConfig});

  Future<List<Map<String, dynamic>>> fetchAssignments(String token) async {
    String cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    String fullUrl = '$cleanBase/assignments';

    while (fullUrl.contains('/api/v1/api/v1/')) {
      fullUrl = fullUrl.replaceAll('/api/v1/api/v1/', '/api/v1/');
    }

    final url = Uri.parse(fullUrl);

    try {
      final response = await http.get(
        url,
        headers: tenantApiConfig.headers(token: token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body);
        return decoded.cast<Map<String, dynamic>>();
      } else {
        Map<String, dynamic> decoded = {};
        try {
          decoded = json.decode(response.body);
        } catch (_) {}
        final msg =
            decoded['detail'] ??
            decoded['message'] ??
            'Gagal mengambil data penugasan';
        throw Exception(msg);
      }
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('Tidak ada koneksi internet. Memuat data tersimpan.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitAssignment({
    required String token,
    required int assignmentId,
    required Stream<List<int>> fileStream,
    required int fileSize,
    required String fileName,
  }) async {
    final uri = Uri.parse('$baseUrl/assignments/$assignmentId/submit');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(
        tenantApiConfig.headers(token: token, includeContentType: false),
      )
      ..files.add(
        http.MultipartFile('file', fileStream, fileSize, filename: fileName),
      );

    try {
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 90),
      );
      final response = await http.Response.fromStream(streamedResponse);
      Map<String, dynamic> decoded = {};
      try {
        decoded = json.decode(response.body) as Map<String, dynamic>;
      } catch (_) {}

      if (response.statusCode == 409 &&
          decoded['detail'] == 'Tugas ini sudah dikumpulkan.') {
        throw const AssignmentAlreadySubmittedException();
      }
      if (response.statusCode == 200 && decoded['success'] == true) {
        final data = decoded['data'];
        if (data is Map<String, dynamic>) return data;
        throw const FormatException('Respons pengumpulan tugas tidak valid.');
      }

      throw Exception(
        decoded['detail'] ?? decoded['message'] ?? 'Gagal mengunggah tugas',
      );
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('Tidak ada koneksi internet. Coba lagi.');
      }
      rethrow;
    }
  }

  Uri attachmentUri(String fileUrl) {
    final parsed = Uri.parse(fileUrl);
    if (parsed.hasScheme) return parsed;

    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final relativePath = fileUrl.startsWith('/')
        ? fileUrl.substring(1)
        : fileUrl;
    return Uri.parse('$cleanBase/$relativePath');
  }

  Future<http.Response> downloadAttachment({
    required String token,
    required String fileUrl,
  }) async {
    final response = await http.get(
      attachmentUri(fileUrl),
      headers: tenantApiConfig.headers(
        token: token,
        includeContentType: false,
      ),
    );
    if (response.statusCode != 200) {
      var message = 'Gagal mengunduh lampiran';
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          message = decoded['detail']?.toString() ?? message;
        }
      } catch (_) {}
      throw Exception(message);
    }
    return response;
  }
}
