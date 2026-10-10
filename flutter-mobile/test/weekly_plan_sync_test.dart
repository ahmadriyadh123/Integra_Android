import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/kurikulum/weekly_plan/local/weekly_plan_local_storage.dart';
import 'package:flutter_application_1/features/kurikulum/weekly_plan/repositories/weekly_plan_repository.dart';
import 'package:flutter_application_1/features/kurikulum/weekly_plan/services/weekly_plan_service.dart';
import 'package:flutter_application_1/services/tenant_api_config.dart';

String _token() {
  String encode(Map<String, dynamic> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode({'alg': 'HS256'})}.${encode({'school_id': 4, 'uid': 10, 'course_id': 30})}.${encode({'sig': 'test'})}';
}

Map<String, dynamic> _plan(int id, String theme) => {
  'id': id,
  'kelas': 'Kelas 1',
  'semester': 'Gasal',
  'tahun_ajaran': '2026/2027',
  'pekan': 'Minggu 1',
  'tema': theme,
  'nama_guru': 'Guru',
  'status': 'published',
};

class _MemoryWeeklyPlanStorage extends WeeklyPlanLocalStorage {
  Map<String, dynamic>? snapshot;

  @override
  Future<Map<String, dynamic>?> loadWeeklyPlanSnapshot({
    required String scope,
  }) async => snapshot;

  @override
  Future<void> saveWeeklyPlanList(
    List<dynamic> plans, {
    required String scope,
    required String cursor,
    required int fullSyncAt,
  }) async {
    snapshot = {'items': plans, 'cursor': cursor, 'full_sync_at': fullSyncAt};
  }
}

class _SequenceWeeklyPlanService extends WeeklyPlanService {
  _SequenceWeeklyPlanService(this.responses)
    : super(
        baseUrl: 'https://example.test',
        tenantApiConfig: TenantApiConfig(schoolId: '4'),
      );

  final List<Map<String, dynamic>> responses;
  var calls = 0;

  @override
  Future<Map<String, dynamic>> syncWeeklyPlanList(
    String token, {
    String? cursor,
  }) async => responses[calls++];
}

void main() {
  test(
    'weekly plan sync merges by id and periodically replaces the snapshot',
    () async {
      final service = _SequenceWeeklyPlanService([
        {
          'items': [_plan(1, 'Tema awal'), _plan(2, 'Dihapus')],
          'removed_ids': <int>[],
          'next_cursor': '2026-10-01T00:00:00Z',
          'full_sync': true,
        },
        {
          'items': [_plan(1, 'Tema diperbarui')],
          'removed_ids': [2],
          'next_cursor': '2026-10-01T00:05:00Z',
          'full_sync': false,
        },
      ]);
      final storage = _MemoryWeeklyPlanStorage();
      final repository = WeeklyPlanRepository(
        apiService: service,
        localStorage: storage,
      );

      await repository.getWeeklyPlanList(_token());
      final updated = await repository.getWeeklyPlanList(_token());
      expect(updated.map((item) => (item.id, item.tema)), [
        (1, 'Tema diperbarui'),
      ]);
      expect(storage.snapshot?['cursor'], '2026-10-01T00:05:00Z');
      expect(service.calls, 2);
    },
  );
}
