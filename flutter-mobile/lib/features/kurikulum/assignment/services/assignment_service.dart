import 'dart:convert';
import 'package:http/http.dart' as http;

class AssignmentService {
  final String baseUrl;

  AssignmentService({required this.baseUrl});

  Future<List<Map<String, dynamic>>> fetchAssignments(String token) async {
    String cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    String fullUrl = '$cleanBase/assignments';

    while (fullUrl.contains('/api/v1/api/v1/')) {
      fullUrl = fullUrl.replaceAll('/api/v1/api/v1/', '/api/v1/');
    }

    final url = Uri.parse(fullUrl);

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body);
        return decoded.cast<Map<String, dynamic>>();
      } else {
        Map<String, dynamic> decoded = {};
        try {
          decoded = json.decode(response.body);
        } catch (_) {}
        final msg = decoded['detail'] ?? decoded['message'] ?? 'Gagal mengambil data penugasan';
        throw Exception(msg);
      }
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('Tidak ada koneksi internet. Memuat data tersimpan.');
      }
      rethrow;
    }
  }
}
