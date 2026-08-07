import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CalendarService {
  final String baseUrl;

  CalendarService({required this.baseUrl});

  Future<Map<String, dynamic>> fetchCalendars(String token) async {
    final url = Uri.parse('$baseUrl/calendar/list');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('Waktu tunggu koneksi habis');
      });

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return jsonResponse['data'] as Map<String, dynamic>;
      } else {
        final message = jsonResponse['detail'] ?? jsonResponse['message'] ?? 'Gagal mengambil data kalender';
        throw Exception(message);
      }
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat mengambil data kalender');
    }
  }
}
