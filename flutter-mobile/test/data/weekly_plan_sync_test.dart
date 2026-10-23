import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/data/local/kurikulum/weekly_plan/weekly_plan_local_storage.dart';
import 'package:flutter_application_1/data/repositories/kurikulum/weekly_plan/weekly_plan_repository.dart';
import 'package:flutter_application_1/data/services/kurikulum/weekly_plan/weekly_plan_service.dart';
import 'package:flutter_application_1/config/api/tenant_api_config.dart';

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
  final Map<int, Uint8List> pdfs = {};

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

  @override
  Future<Uint8List?> loadWeeklyPlanPdf(
    int planId, {
    required String scope,
  }) async => pdfs[planId];

  @override
  Future<void> saveWeeklyPlanPdf(
    int planId,
    Uint8List pdfBytes, {
    required String scope,
  }) async {
    pdfs[planId] = pdfBytes;
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
  final cursors = <String?>[];
  Uint8List pdf = Uint8List.fromList([1, 2, 3]);
  var pdfCalls = 0;

  @override
  Future<Map<String, dynamic>> syncWeeklyPlanList(
    String token, {
    String? cursor,
  }) async {
    cursors.add(cursor);
    return responses[calls++];
  }

  @override
  Future<Uint8List> fetchWeeklyPlanPdfFile(int planId, String token) async {
    pdfCalls++;
    return pdf;
  }
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
        {
          'items': [_plan(3, 'Full refresh')],
          'removed_ids': <int>[],
          'next_cursor': '2026-10-01T01:00:00Z',
          'full_sync': true,
        },
      ]);
      final storage = _MemoryWeeklyPlanStorage();
      final repository = WeeklyPlanRepository(
        apiService: service,
        localStorage: storage,
      );

      await repository.getWeeklyPlanList(_token());
      final cached = await repository.getWeeklyPlanList(_token());
      expect(cached.map((item) => (item.id, item.tema)), [
        (1, 'Tema awal'),
        (2, 'Dihapus'),
      ]);
      expect(service.calls, 1);
      final updated = await repository.getWeeklyPlanList(
        _token(),
        forceRefresh: true,
      );
      expect(updated.map((item) => (item.id, item.tema)), [
        (1, 'Tema diperbarui'),
      ]);
      expect(storage.snapshot?['cursor'], '2026-10-01T00:05:00Z');
      final refreshed = await repository.getWeeklyPlanList(
        _token(),
        forceRefresh: true,
      );
      expect(refreshed.map((item) => (item.id, item.tema)), [
        (3, 'Full refresh'),
      ]);
      expect(service.cursors, [
        null,
        '2026-10-01T00:00:00Z',
        '2026-10-01T00:05:00Z',
      ]);
      expect(service.calls, 3);
    },
  );

  test('weekly plan PDF is cached until explicitly refreshed', () async {
    final service = _SequenceWeeklyPlanService([]);
    final storage = _MemoryWeeklyPlanStorage();
    final repository = WeeklyPlanRepository(
      apiService: service,
      localStorage: storage,
    );

    expect(await repository.getWeeklyPlanPdfFile(8, _token()), [1, 2, 3]);
    service.pdf = Uint8List.fromList([4, 5]);
    expect(await repository.getWeeklyPlanPdfFile(8, _token()), [1, 2, 3]);
    expect(service.pdfCalls, 1);
    expect(
      await repository.getWeeklyPlanPdfFile(8, _token(), forceRefresh: true),
      [4, 5],
    );
    expect(service.pdfCalls, 2);
  });

  test('empty weekly plan snapshot is revalidated on page load', () async {
    final service = _SequenceWeeklyPlanService([
      {
        'items': [_plan(21, 'Tersedia')],
        'removed_ids': <int>[],
        'next_cursor': '2026-10-12T00:00:00Z',
        'full_sync': true,
      },
    ]);
    final storage = _MemoryWeeklyPlanStorage()
      ..snapshot = {
        'items': <Map<String, dynamic>>[],
        'cursor': '2026-10-11T00:00:00Z',
        'full_sync_at': DateTime.now().millisecondsSinceEpoch,
      };
    final repository = WeeklyPlanRepository(
      apiService: service,
      localStorage: storage,
    );

    final result = await repository.getWeeklyPlanList(_token());

    expect(result.single.tema, 'Tersedia');
    expect(service.calls, 1);
    expect(service.cursors, [null]);
  });
}
