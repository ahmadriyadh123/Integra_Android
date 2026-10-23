import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/config/api/tenant_api_config.dart';
import 'package:flutter_application_1/domain/models/cbt_answer.dart';
import '../../../model/kurikulum/cbt/cbt_model.dart';

class CbtService {
  final String baseUrl;
  final TenantApiConfig tenantApiConfig;
  final http.Client? httpClient;

  CbtService({
    required this.baseUrl,
    required this.tenantApiConfig,
    this.httpClient,
  });

  Future<http.Response> _get(Uri url, String token) {
    final headers = tenantApiConfig.headers(token: token);
    final client = httpClient;
    final configuredClient = tenantApiConfig.httpClient;
    return client != null
        ? client.get(url, headers: headers)
        : configuredClient != null
        ? configuredClient.get(url, headers: headers)
        : http.get(url, headers: headers);
  }

  Future<http.Response> _post(
    Uri url,
    String token, {
    required String body,
  }) {
    final headers = tenantApiConfig.headers(token: token);
    final client = httpClient;
    final configuredClient = tenantApiConfig.httpClient;
    return client != null
        ? client.post(url, headers: headers, body: body)
        : configuredClient != null
        ? configuredClient.post(url, headers: headers, body: body)
        : http.post(url, headers: headers, body: body);
  }

  /// Ambil daftar jadwal ujian CBT dari middleware
  Future<List<CbtExamSchedule>> fetchCbtSchedules(String token) async {
    if (token.trim().isEmpty) {
      throw Exception(
        'Token login kosong. Jalankan login dan kirim AUTH_TOKEN yang valid.',
      );
    }

    final url = Uri.parse('$baseUrl/cbt/schedules');

    try {
      final response = await _get(url, token)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Waktu tunggu koneksi habis');
            },
          );

      final jsonResponse = _successfulResponse(
        response,
        fallbackMessage: 'Gagal mengambil data CBT',
      );
      final data = _asObject(
        jsonResponse['data'],
        'Daftar jadwal CBT tidak valid.',
      );
      final rawData = data['exams'];
      if (rawData is! List) {
        throw const FormatException('Daftar jadwal CBT tidak valid.');
      }
      return rawData
          .map(
            (item) => CbtExamSchedule.fromJson(
              _asObject(item, 'Record jadwal CBT tidak valid.'),
            ),
          )
          .toList();
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat mengambil data CBT');
    }
  }

  Future<CbtScheduleSyncResult> syncCbtSchedules(
    String token, {
    String? cursor,
  }) async {
    if (token.trim().isEmpty) {
      throw Exception('Token login kosong. Jalankan login terlebih dahulu.');
    }
    final url = Uri.parse(
      '$baseUrl/cbt/schedules/sync',
    ).replace(queryParameters: cursor == null ? null : {'cursor': cursor});
    final response = await _get(url, token)
        .timeout(const Duration(seconds: 15));
    final jsonResponse = _successfulResponse(
      response,
      fallbackMessage: 'Gagal menyinkronkan jadwal CBT',
    );
    return CbtScheduleSyncResult.fromJson(
      _asObject(jsonResponse['data'], 'Data sinkronisasi CBT tidak valid.'),
    );
  }

  /// Verifikasi token ujian ke middleware/Odoo
  Future<bool> verifyExamToken(
    String token,
    int jadwalId,
    String tokenInput,
  ) async {
    final url = Uri.parse('$baseUrl/cbt/verify-token');
    try {
      final response = await _post(
            url,
            token,
            body: json.encode({
              'jadwal_ujian_id': jadwalId,
              'token_input': tokenInput.trim(),
            }),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Waktu tunggu koneksi habis');
            },
          );

      final jsonResponse = _decodeObject(response.body);
      if (response.statusCode == 200) {
        if (jsonResponse['success'] == true && jsonResponse['data'] == true) {
          return true;
        }
        if (jsonResponse['success'] == true &&
            jsonResponse['data'] != false &&
            jsonResponse['data'] != null) {
          throw const FormatException('Respons verifikasi token CBT tidak valid.');
        }
        final message =
            jsonResponse['message'] ??
            'Token ujian tidak valid. Periksa kembali token dari pengawas.';
        throw Exception(message);
      } else {
        final detail = jsonResponse['detail'];
        final responseMessage = jsonResponse['message'];
        final message = detail is String
            ? detail
            : responseMessage is String
            ? responseMessage
            : 'Verifikasi token gagal';
        throw Exception(message);
      }
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat verifikasi token');
    }
  }

  /// Ambil daftar soal ujian berdasarkan jadwal_id
  Future<CbtExamData> fetchExamQuestions(
    String token,
    int jadwalId,
  ) async {
    final url = Uri.parse('$baseUrl/cbt/questions/$jadwalId');
    try {
      final response = await _get(url, token)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Waktu tunggu koneksi habis');
            },
          );

      final jsonResponse = _successfulResponse(
        response,
        fallbackMessage: 'Gagal mengambil soal ujian',
      );
      return CbtExamData.fromJson(
        _asObject(jsonResponse['data'], 'Data ujian CBT tidak valid.'),
      );
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat mengambil soal ujian');
    }
  }

  /// Submit jawaban ujian
  Future<CbtSubmitResult> submitExam(
    String token,
    int jadwalId,
    List<CbtAnswer> answers,
    String? waktuMulai,
  ) async {
    final url = Uri.parse('$baseUrl/cbt/submit');
    try {
      final response = await _post(
            url,
            token,
            body: json.encode({
              'jadwal_ujian_id': jadwalId,
              'answers': answers
                  .map(
                    (answer) => {
                      'soal_id': answer.questionId,
                      'jawaban_pilihan_id': answer.selectedOptionId,
                      'jawaban_text': null,
                      'jenis_soal': answer.questionType,
                    },
                  )
                  .toList(),
              'waktu_mulai': ?waktuMulai,
            }),
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException('Waktu tunggu koneksi habis');
            },
          );

      final jsonResponse = _successfulResponse(
        response,
        fallbackMessage: 'Gagal menyimpan jawaban ujian',
      );
      return CbtSubmitResult.fromJson(
        _asObject(jsonResponse['data'], 'Respons pengumpulan CBT tidak valid.'),
      );
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat mengirim jawaban ujian');
    }
  }

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = json.decode(body);
    return _asObject(decoded, 'Respons CBT bukan objek JSON yang valid.');
  }

  Map<String, dynamic> _asObject(dynamic value, String message) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw FormatException(message);
    }
    return Map<String, dynamic>.from(value);
  }

  Map<String, dynamic> _successfulResponse(
    http.Response response, {
    required String fallbackMessage,
  }) {
    final jsonResponse = _decodeObject(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse;
    }
    final detail = jsonResponse['detail'];
    final message = jsonResponse['message'];
    throw Exception(
      detail is String && detail.isNotEmpty
          ? detail
          : message is String && message.isNotEmpty
          ? message
          : fallbackMessage,
    );
  }
}
