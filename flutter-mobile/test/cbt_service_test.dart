import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/kurikulum/cbt/models/cbt_model.dart';
import 'package:flutter_application_1/features/kurikulum/cbt/services/cbt_service.dart';
import 'package:flutter_application_1/services/tenant_api_config.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _token() {
  String encodeSegment(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return [
    encodeSegment({'alg': 'HS256'}),
    encodeSegment({'school_id': 4, 'uid': 10}),
    encodeSegment('signature'),
  ].join('.');
}

void main() {
  test('CBT schedule sync validates and returns typed schedule data', () async {
    final service = CbtService(
      baseUrl: 'https://example.com/api/v1',
      tenantApiConfig: TenantApiConfig(schoolId: '4'),
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/v1/cbt/schedules/sync');
        expect(request.url.queryParameters['cursor'], 'cursor-1');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'is_full_sync': false,
              'cursor': 'cursor-2',
              'removed_ids': [3],
              'exams': [
                {
                  'id': 7,
                  'judul_ujian': 'Ujian Matematika',
                  'jenis_ujian': 'UTS',
                  'rentang_waktu': '10:00-11:00',
                  'durasi_menit': 60,
                  'jumlah_soal': 20,
                  'status': 'aktif',
                },
              ],
            },
          }),
          200,
        );
      }),
    );

    final result = await service.syncCbtSchedules(_token(), cursor: 'cursor-1');

    expect(result, isA<CbtScheduleSyncResult>());
    expect(result.isFullSync, isFalse);
    expect(result.removedIds, [3]);
    expect(result.exams.single.id, 7);
    expect(result.exams.single.title, 'Ujian Matematika');
  });

  test('CBT schedule sync rejects malformed exam records', () async {
    final service = CbtService(
      baseUrl: 'https://example.com/api/v1',
      tenantApiConfig: TenantApiConfig(schoolId: '4'),
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'is_full_sync': true,
              'cursor': 'cursor-1',
              'removed_ids': [],
              'exams': [
                {'id': 'not-an-id'},
              ],
            },
          }),
          200,
        ),
      ),
    );

    await expectLater(
      service.syncCbtSchedules(_token()),
      throwsA(isA<FormatException>()),
    );
  });

  test('CBT question response requires a questions list', () {
    expect(
      () => CbtExamData.fromJson({'judul_ujian': 'Ujian'}),
      throwsA(isA<FormatException>()),
    );
  });
}
