import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/tenant_api_config.dart';

import '../models/notification_model.dart';

class NotificationService {
  final String baseUrl;
  final TenantApiConfig tenantApiConfig;
  final http.Client? httpClient;

  NotificationService({
    required this.baseUrl,
    required this.tenantApiConfig,
    this.httpClient,
  });

  http.Client get _effectiveClient =>
      tenantApiConfig.httpClient ?? httpClient ?? http.Client();

  Map<String, String> _headers(String token) =>
      tenantApiConfig.headers(token: token);

  /// Panggil GET /notifications?cursor=<timestamp>
  ///
  /// Mengembalikan daftar notifikasi baru sejak cursor dan next_cursor
  /// untuk poll berikutnya.
  Future<NotificationFetchResult> fetchNotifications(
    String token, {
    String? cursor,
  }) async {
    final url = Uri.parse('$baseUrl/notifications');
    try {
      final response = await _effectiveClient
          .get(url, headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded['success'] == true) {
        final data = decoded['data'] as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [];

        final notifications = items.map((item) {
          final kategori = item['kategori'] as String? ?? 'general';
          return AppNotification.fromApiItem(item, kategori);
        }).toList();

        return NotificationFetchResult(
          notifications: notifications,
          nextCursor: data['next_cursor'] as String?,
          fullSync: data['full_sync'] as bool? ?? cursor == null,
        );
      }

      throw Exception(
        decoded['detail']?.toString() ??
            decoded['message']?.toString() ??
            'Gagal mengambil notifikasi',
      );
    } on TimeoutException {
      throw Exception('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server: ${e.message}');
    }
  }
}

class NotificationFetchResult {
  final List<AppNotification> notifications;
  final String? nextCursor;
  final bool fullSync;

  NotificationFetchResult({
    required this.notifications,
    this.nextCursor,
    this.fullSync = false,
  });
}
