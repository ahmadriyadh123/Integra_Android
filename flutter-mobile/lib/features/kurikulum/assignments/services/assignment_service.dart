import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/tenant_api_config.dart';
import '../models/assignment_model.dart';

class AssignmentAlreadySubmittedException implements Exception {
  const AssignmentAlreadySubmittedException();

  @override
  String toString() => 'Tugas ini sudah dikumpulkan sebelumnya.';
}

class AssignmentFileUpload {
  final Stream<List<int>> stream;
  final int size;
  final String fileName;

  const AssignmentFileUpload({
    required this.stream,
    required this.size,
    required this.fileName,
  });
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
      final headers = tenantApiConfig.headers(token: token);
      final response =
          await tenantApiConfig.httpClient?.get(url, headers: headers) ??
          await http.get(url, headers: headers);

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
        throw Exception('Tidak ada koneksi internet.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> syncAssignments(
    String token, {
    String? cursor,
  }) async {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    var base = cleanBase;
    while (base.contains('/api/v1/api/v1/')) {
      base = base.replaceAll('/api/v1/api/v1/', '/api/v1/');
    }
    final uri = Uri.parse(
      '$base/assignments/sync',
    ).replace(queryParameters: cursor == null ? null : {'cursor': cursor});
    final headers = tenantApiConfig.headers(token: token);
    final response =
        await tenantApiConfig.httpClient?.get(uri, headers: headers) ??
        await http.get(uri, headers: headers);
    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 &&
        decoded is Map &&
        decoded['success'] == true &&
        decoded['data'] is Map) {
      return Map<String, dynamic>.from(decoded['data']);
    }
    throw Exception(
      decoded is Map
          ? decoded['detail'] ?? 'Gagal menyinkronkan data penugasan'
          : 'Respons sinkronisasi penugasan tidak valid.',
    );
  }

  Future<AssignmentSubmissionResult> submitAssignment({
    required String token,
    required int assignmentId,
    required List<AssignmentFileUpload> files,
  }) async {
    final uri = Uri.parse('$baseUrl/assignments/$assignmentId/submit');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(
        tenantApiConfig.headers(token: token, includeContentType: false),
      )
      ..files.addAll(
        files.map(
          (file) => http.MultipartFile(
            'files',
            file.stream,
            file.size,
            filename: file.fileName,
          ),
        ),
      );

    try {
      final streamedResponse =
          await (tenantApiConfig.httpClient?.send(request) ?? request.send())
              .timeout(
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
        if (data is Map && data.keys.every((key) => key is String)) {
          return AssignmentSubmissionResult.fromJson(
            Map<String, dynamic>.from(data),
          );
        }
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

  Future<AssignmentSubmissionResult> updateSubmissionAttachments({
    required String token,
    required int assignmentId,
    required List<AssignmentFileUpload> files,
    required List<int> removeAttachmentIds,
  }) async {
    final uri = Uri.parse('$baseUrl/assignments/$assignmentId/submission');
    final request = http.MultipartRequest('PATCH', uri)
      ..headers.addAll(
        tenantApiConfig.headers(token: token, includeContentType: false),
      )
      ..fields['remove_attachment_ids'] = jsonEncode(removeAttachmentIds)
      ..files.addAll(
        files.map(
          (file) => http.MultipartFile(
            'files',
            file.stream,
            file.size,
            filename: file.fileName,
          ),
        ),
      );

    try {
      final streamedResponse =
          await (tenantApiConfig.httpClient?.send(request) ?? request.send())
              .timeout(
        const Duration(seconds: 90),
      );
      final response = await http.Response.fromStream(streamedResponse);
      Map<String, dynamic> decoded = {};
      try {
        final body = json.decode(response.body);
        if (body is Map && body.keys.every((key) => key is String)) {
          decoded = Map<String, dynamic>.from(body);
        }
      } catch (_) {}

      if (response.statusCode == 200 && decoded['success'] == true) {
        final data = decoded['data'];
        if (data is Map && data.keys.every((key) => key is String)) {
          return AssignmentSubmissionResult.fromJson(
            Map<String, dynamic>.from(data),
          );
        }
        throw const FormatException(
          'Respons perubahan lampiran tugas tidak valid.',
        );
      }

      throw Exception(
        decoded['detail'] ??
            decoded['message'] ??
            'Gagal memperbarui lampiran tugas',
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
    final uri = attachmentUri(fileUrl);
    final headers = tenantApiConfig.headers(
      token: token,
      includeContentType: false,
    );
    final response =
        await tenantApiConfig.httpClient?.get(uri, headers: headers) ??
        await http.get(uri, headers: headers);
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
