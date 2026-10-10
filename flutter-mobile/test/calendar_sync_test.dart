import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/calendar/local/calendar_local_storage.dart';
import 'package:flutter_application_1/features/calendar/repositories/calendar_repository.dart';
import 'package:flutter_application_1/features/calendar/services/calendar_service.dart';
import 'package:flutter_application_1/services/tenant_api_config.dart';

String _token({int schoolId = 8, int userId = 20, int courseId = 30}) {
  String encode(Map<String, dynamic> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode({'alg': 'HS256'})}.${encode({'school_id': schoolId, 'uid': userId, 'course_id': courseId})}.${encode({'sig': 'test'})}';
}

Map<String, dynamic> _item(int id, String semester) => {
  'id': id,
  'kelas': 'Kelas 1',
  'semester': semester,
  'tahun_ajaran': '2026/2027',
  'link_dokumen': '',
  'status': 'active',
};

class _MemoryCalendarStorage extends CalendarLocalStorage {
  final snapshots = <String, Map<String, dynamic>>{};

  @override
  Future<Map<String, dynamic>?> loadSnapshot({
    required String cacheScope,
  }) async => snapshots[cacheScope];

  @override
  Future<void> saveSnapshot({
    required String cacheScope,
    required List<Map<String, dynamic>> items,
    required String cursor,
    required int fullSyncAt,
  }) async {
    snapshots[cacheScope] = {
      'items': items,
      'cursor': cursor,
      'full_sync_at': fullSyncAt,
    };
  }
}

class _SequenceCalendarService extends CalendarService {
  _SequenceCalendarService(this.responses)
    : super(
        baseUrl: 'https://example.test',
        tenantApiConfig: TenantApiConfig(schoolId: '8'),
      );

  final List<Map<String, dynamic>> responses;
  var calls = 0;

  @override
  Future<Map<String, dynamic>> syncCalendars(
    String token, {
    String? cursor,
  }) async => responses[calls++];
}

void main() {
  test(
    'merges calendar delta by id while preserving class-scoped cache',
    () async {
      final service = _SequenceCalendarService([
        {
          'items': [_item(1, 'Semester 1'), _item(2, 'Semester 2')],
          'removed_ids': <int>[],
          'next_cursor': '2026-10-01T00:00:00Z',
          'full_sync': true,
        },
        {
          'items': [_item(1, 'Semester 1 revisi')],
          'removed_ids': [2],
          'next_cursor': '2026-10-01T00:05:00Z',
          'full_sync': false,
        },
      ]);
      final storage = _MemoryCalendarStorage();
      final repository = CalendarRepository(
        apiService: service,
        localStorage: storage,
      );

      await repository.getCalendars(_token());
      final delta = await repository.getCalendars(_token());
      expect(delta.map((item) => (item.id, item.semester)), [
        (1, 'Semester 1 revisi'),
      ]);
      expect(
        await storage.loadSnapshot(
          cacheScope: repository.cacheScopeForToken(_token(courseId: 31)),
        ),
        isNull,
      );
    },
  );
}
