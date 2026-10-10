import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/kehadiran/local/attendance_local_storage.dart';
import 'package:flutter_application_1/features/kehadiran/repositories/attendance_repository.dart';
import 'package:flutter_application_1/features/kehadiran/services/attendance_service.dart';
import 'package:flutter_application_1/services/tenant_api_config.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _token(int schoolId, int userId, int studentId) {
  String encode(Map<String, dynamic> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode({'alg': 'HS256'})}.${encode({'school_id': schoolId, 'uid': userId, 'student_id': studentId})}.${encode({'sig': 'test'})}';
}

Map<String, dynamic> _record(int id, String remark) => {
  'id': id,
  'student_name': 'Siswa',
  'course_name': 'Kelas 1',
  'batch_name': 'A',
  'attendance_date': '2026-10-01',
  'present': true,
  'excused': false,
  'absent': false,
  'sick': false,
  'status': 'hadir',
  'remark': remark,
};

class _MemoryAttendanceStorage extends AttendanceLocalStorage {
  final Map<String, Map<String, dynamic>> snapshots = {};

  @override
  Future<Map<String, dynamic>?> loadSnapshot({required String scope}) async =>
      snapshots[scope];

  @override
  Future<void> saveSnapshot({
    required String scope,
    required List<Map<String, dynamic>> items,
    required String cursor,
    required int fullSyncAt,
  }) async {
    snapshots[scope] = {
      'items': items,
      'cursor': cursor,
      'full_sync_at': fullSyncAt,
    };
  }
}

void main() {
  test(
    'applies attendance delta by id and isolates snapshots by student',
    () async {
      var call = 0;
      final client = MockClient((request) async {
        call++;
        final payload = call == 1
            ? {
                'items': [_record(1, 'awal'), _record(2, 'hapus')],
                'removed_ids': <int>[],
                'next_cursor': '2026-10-01T00:00:00Z',
                'full_sync': true,
              }
            : {
                'items': [_record(1, 'perubahan')],
                'removed_ids': [2],
                'next_cursor': '2026-10-01T00:05:00Z',
                'full_sync': false,
              };
        return http.Response(
          jsonEncode({'success': true, 'data': payload}),
          200,
        );
      });
      final storage = _MemoryAttendanceStorage();
      final service = _TestAttendanceService(client);
      final testedRepository = AttendanceRepository(
        apiService: service,
        localStorage: storage,
      );
      final token = _token(8, 20, 30);

      expect((await testedRepository.getAttendanceHistory(token)).length, 2);
      final updated = await testedRepository.getAttendanceHistory(token);
      expect(updated.map((item) => item.id), [1]);
      expect(storage.snapshots.keys.single, contains('student_30'));
      expect(
        await storage.loadSnapshot(
          scope: testedRepository.cacheScopeForToken(_token(8, 20, 31)),
        ),
        isNull,
      );
      expect(call, 2);
      client.close();
    },
  );
}

class _TestAttendanceService extends AttendanceService {
  _TestAttendanceService(this.client)
    : super(
        baseUrl: 'https://example.test/api/v1',
        tenantApiConfig: TenantApiConfig(schoolId: '8'),
      );

  final MockClient client;

  @override
  Future<Map<String, dynamic>> syncAttendanceHistory(
    String token, {
    String? cursor,
    int limit = 500,
  }) async {
    final query = <String, String>{'limit': '$limit'};
    if (cursor != null) query['cursor'] = cursor;
    final response = await client.get(
      Uri.parse(
        '$baseUrl/attendance/history/sync',
      ).replace(queryParameters: query),
    );
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }
}
