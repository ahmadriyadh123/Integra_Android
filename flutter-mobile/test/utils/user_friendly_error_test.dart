import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/utils/user_friendly_error.dart';

void main() {
  group('userFriendlyError', () {
    test('turns connection failures into a helpful next step', () {
      expect(
        userFriendlyError(const SocketException('Failed host lookup')),
        'Tidak dapat terhubung ke layanan. '
        'Periksa koneksi internet Anda, lalu coba lagi.',
      );
      expect(
        userFriendlyError(TimeoutException('timeout')),
        'Koneksi terlalu lama. '
        'Periksa koneksi internet Anda, lalu coba lagi.',
      );
    });

    test('hides technical backend and parser details', () {
      expect(
        userFriendlyError(
          Exception('psycopg2.OperationalError: database unavailable'),
        ),
        'Terjadi kendala saat memproses permintaan. Silakan coba lagi.',
      );
      expect(
        userFriendlyError(
          const FormatException(
            'Token dari server tidak sesuai dengan sekolah tenant.',
          ),
        ),
        'Sesi Anda tidak sesuai dengan sekolah yang dipilih. '
        'Silakan login kembali.',
      );
    });

    test('keeps actionable user-facing validation messages', () {
      expect(
        userFriendlyError(Exception('Password baru minimal 6 karakter.')),
        'Password baru minimal 6 karakter.',
      );
    });
  });
}
