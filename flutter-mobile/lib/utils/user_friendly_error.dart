import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show ClientException;

const _defaultErrorMessage =
    'Terjadi kendala saat memproses permintaan. Silakan coba lagi.';
const _connectionErrorMessage =
    'Tidak dapat terhubung ke layanan. Periksa koneksi internet Anda, lalu coba lagi.';
const _technicalErrorMarkers = [
  'database',
  'odoo',
  'postgres',
  'psycopg',
  'sqlalchemy',
  'traceback',
  'internal server error',
  'socketexception',
  'clientexception',
  'connection refused',
  'connection reset',
  'failed host lookup',
  'network is unreachable',
  'tenant',
  'jwt',
  'token dari server',
  'uri.',
  'null check operator',
  'type ',
  'format exception',
  'platformexception',
  'status code 500',
  'http 500',
  'server mengembalikan status',
  'status code',
  'status:',
];

String userFriendlyError(
  Object error, {
  String fallback = _defaultErrorMessage,
}) {
  if (error is TimeoutException) {
    return 'Koneksi terlalu lama. Periksa koneksi internet Anda, lalu coba lagi.';
  }
  if (error is SocketException || error is ClientException) {
    return _connectionErrorMessage;
  }

  final message = error.toString().trim();
  final normalized = message.toLowerCase();
  if (normalized.contains('gagal terhubung') ||
      normalized.contains('tidak ada koneksi internet') ||
      normalized.contains('koneksi ke server terlalu lama')) {
    return _connectionErrorMessage;
  }
  if (normalized.contains('token dari server') ||
      (normalized.contains('token') && normalized.contains('sekolah'))) {
    return 'Sesi Anda tidak sesuai dengan sekolah yang dipilih. Silakan login kembali.';
  }
  if (_technicalErrorMarkers.any(normalized.contains)) return fallback;

  final readableMessage = message
      .replaceFirst(RegExp(r'^(Exception|StateError|ArgumentError):\s*'), '')
      .trim();
  if (readableMessage.isEmpty) return fallback;
  return readableMessage;
}
