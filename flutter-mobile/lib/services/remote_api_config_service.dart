import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class RemoteApiConfigException implements Exception {
  const RemoteApiConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RemoteApiConfigService {
  static const configUrl =
      'https://kp-sekolah.asetkoptii.com/mobile-api/client-config';
  static const requestTimeout = Duration(seconds: 4);

  final http.Client? client;

  const RemoteApiConfigService({this.client});

  Future<String> fetchBaseUrl() async {
    final uri = Uri.parse(configUrl);
    final response = await (client?.get(uri) ?? http.get(uri))
        .timeout(requestTimeout);
    if (response.statusCode != 200) {
      throw RemoteApiConfigException(
        'Konfigurasi alamat API gagal dimuat (HTTP ${response.statusCode}).',
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const RemoteApiConfigException(
        'Format konfigurasi alamat API tidak valid.',
      );
    }

    if (decoded is! Map || decoded['api_base_url'] is! String) {
      throw const RemoteApiConfigException(
        'Konfigurasi tidak memiliki api_base_url yang valid.',
      );
    }

    final rawBaseUrl = (decoded['api_base_url'] as String).trim();
    final baseUrl = rawBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    final baseUri = Uri.tryParse(baseUrl);
    if (baseUri == null ||
        baseUri.scheme != 'https' ||
        baseUri.host.isEmpty ||
        baseUri.userInfo.isNotEmpty ||
        baseUri.hasQuery ||
        baseUri.hasFragment ||
        !baseUri.path.endsWith('/api/v1')) {
      throw const RemoteApiConfigException(
        'Alamat API remote harus berupa URL HTTPS yang berakhir dengan /api/v1.',
      );
    }

    return baseUrl;
  }
}
