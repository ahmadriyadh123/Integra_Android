import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/data/local/kurikulum/assignments/assignment_local_storage.dart';
import 'package:flutter_application_1/data/repositories/kurikulum/assignments/assignment_repository.dart';
import 'package:flutter_application_1/data/services/kurikulum/assignments/assignment_service.dart';
import 'package:flutter_application_1/data/local/e-rapor/rapor_local_storage.dart';
import 'package:flutter_application_1/data/repositories/e-rapor/rapor_repository.dart';
import 'package:flutter_application_1/data/services/e-rapor/rapor_service.dart';
import 'package:flutter_application_1/data/local/kurikulum/buku-komunikasi/buku_komunikasi_local_storage.dart';
import 'package:flutter_application_1/data/repositories/kurikulum/buku-komunikasi/buku_komunikasi_repository.dart';
import 'package:flutter_application_1/data/services/kurikulum/buku-komunikasi/buku_komunikasi_service.dart';
import 'package:flutter_application_1/data/local/kurikulum/cbt/cbt_local_storage.dart';
import 'package:flutter_application_1/data/model/kurikulum/cbt/cbt_model.dart';
import 'package:flutter_application_1/data/repositories/kurikulum/cbt/cbt_repository.dart';
import 'package:flutter_application_1/data/services/kurikulum/cbt/cbt_service.dart';
import 'package:flutter_application_1/data/local/tagihan/tagihan_local_storage.dart';
import 'package:flutter_application_1/data/repositories/tagihan/tagihan_repository.dart';
import 'package:flutter_application_1/data/services/tagihan/tagihan_service.dart';
import 'package:flutter_application_1/config/api/tenant_api_config.dart';

const _token = 'header.eyJzY2hvb2xfaWQiOjEsInVpZCI6Mn0.signature';
final _tenant = TenantApiConfig(schoolId: '1');

String _studentToken() {
  final payload = base64Url
      .encode(
        utf8.encode(jsonEncode({'school_id': 1, 'uid': 2, 'student_id': 2})),
      )
      .replaceAll('=', '');
  return 'header.$payload.signature';
}

class _AssignmentStorage extends AssignmentLocalStorage {
  final Map<String, Map<String, dynamic>> snapshots = {};

  @override
  Future<Map<String, dynamic>?> loadAssignmentSnapshot({
    required String cacheScope,
  }) async => snapshots[cacheScope];

  @override
  Future<void> saveAssignments(
    List<Map<String, dynamic>> assignments, {
    required String cacheScope,
    String? cursor,
    int? fullSyncAt,
  }) async {
    snapshots[cacheScope] = {
      'cache_version': AssignmentLocalStorage.cacheVersion,
      'items': List<Map<String, dynamic>>.from(assignments),
      'cursor': cursor,
      'full_sync_at': fullSyncAt,
    };
  }
}

class _AssignmentService extends AssignmentService {
  _AssignmentService()
    : super(baseUrl: 'https://example.com', tenantApiConfig: _tenant);

  Map<String, dynamic> result = {};
  bool fail = false;
  final cursorRequests = <String?>[];

  @override
  Future<Map<String, dynamic>> syncAssignments(
    String token, {
    String? cursor,
  }) async {
    cursorRequests.add(cursor);
    if (fail) throw Exception('offline');
    return result;
  }
}

class _CbtStorage extends CbtLocalStorage {
  final Map<String, Map<String, dynamic>> snapshots = {};

  @override
  Future<Map<String, dynamic>?> loadCbtSnapshot({
    required String scope,
  }) async => snapshots[scope];

  @override
  Future<void> saveCbtSchedules(
    List<dynamic> schedules, {
    required String scope,
    String? cursor,
    int? fullSyncAt,
  }) async {
    snapshots[scope] = {
      'items': schedules,
      'cursor': cursor,
      'full_sync_at': fullSyncAt,
    };
  }
}

class _CbtService extends CbtService {
  _CbtService()
    : super(baseUrl: 'https://example.com', tenantApiConfig: _tenant);

  List<dynamic> schedules = [];
  List<dynamic> deltaSchedules = [];
  List<dynamic> removedIds = [];
  bool isFullSync = true;
  bool fail = false;
  final cursors = <String?>[];

  @override
  Future<CbtScheduleSyncResult> syncCbtSchedules(
    String token, {
    String? cursor,
  }) async {
    cursors.add(cursor);
    if (fail) throw Exception('offline');
    return CbtScheduleSyncResult.fromJson({
      'is_full_sync': isFullSync,
      'exams': isFullSync ? schedules : deltaSchedules,
      'removed_ids': removedIds,
      'cursor': cursor == null ? 'cbt-1' : 'cbt-2',
    });
  }
}

class _TagihanStorage extends TagihanLocalStorage {
  final Map<String, Map<String, dynamic>> snapshots = {};
  final Set<String> freshSnapshots = {};
  final Map<String, String> cursors = {};
  final Map<String, int> fullSyncTimes = {};

  String _key(String? state, String scope) => '$scope:${state ?? 'all'}';

  @override
  Future<String?> loadCursor(String scope) async => cursors[scope];

  @override
  Future<int?> loadFullSyncAt(String scope) async => fullSyncTimes[scope];

  @override
  Future<void> saveFullSyncAt(String scope, int timestamp) async {
    fullSyncTimes[scope] = timestamp;
  }

  @override
  Future<Map<String, dynamic>?> loadTagihanSummary(
    String? paymentState, {
    required String scope,
  }) async => snapshots[_key(paymentState, scope)];

  @override
  Future<void> saveTagihanSummary(
    String? paymentState,
    Map<String, dynamic> data, {
    required String scope,
    String? cursor,
  }) async {
    final key = _key(paymentState, scope);
    snapshots[key] = Map.from(data);
    if (cursor != null) cursors[scope] = cursor;
    freshSnapshots.add(key);
  }

  @override
  Future<bool> isTagihanSummaryFresh(
    String? paymentState, {
    required String scope,
  }) async => freshSnapshots.contains(_key(paymentState, scope));
}

class _TagihanService extends TagihanService {
  _TagihanService()
    : super(baseUrl: 'https://example.com', tenantApiConfig: _tenant);

  Map<String, dynamic> summary = {};
  bool fail = false;
  int fetchCount = 0;

  @override
  Future<Map<String, dynamic>> fetchTagihan(
    String token, {
    String? paymentState,
  }) async {
    fetchCount++;
    if (fail) throw Exception('offline');
    return summary;
  }

  @override
  Future<Map<String, dynamic>> syncTagihan(
    String token, {
    String? cursor,
  }) async {
    final data = await fetchTagihan(token);
    final count = data['total_invoices'] as int? ?? 0;
    return {
      'items': List.generate(
        count,
        (index) => {'id': index + 1, 'residual_amount': 0},
      ),
      'all_active_ids': List.generate(count, (index) => index + 1),
      'next_cursor': 'tagihan-$fetchCount',
      'full_sync': true,
    };
  }
}

class _RaporStorage extends RaporLocalStorage {
  Map<String, dynamic>? snapshot;
  final Map<int, Map<String, dynamic>> details = {};
  final Map<int, Uint8List> pdfs = {};
  String? listScope;
  String? detailScope;

  @override
  Future<Map<String, dynamic>?> loadRaporListSnapshot({
    required String scope,
  }) async {
    listScope = scope;
    return snapshot;
  }

  @override
  Future<void> saveRaporList(
    List<dynamic> raporList, {
    required String scope,
    String? cursor,
    int? fullSyncAt,
  }) async {
    listScope = scope;
    snapshot = {
      'items': List<dynamic>.from(raporList),
      'cursor': cursor,
      'full_sync_at': fullSyncAt,
    };
  }

  @override
  Future<Map<String, dynamic>?> loadRaporDetail(
    int raporId, {
    required String scope,
  }) async {
    detailScope = scope;
    return details[raporId];
  }

  @override
  Future<void> saveRaporDetail(
    int raporId,
    Map<String, dynamic> detail, {
    required String scope,
  }) async {
    detailScope = scope;
    details[raporId] = Map.from(detail);
  }

  @override
  Future<Uint8List?> loadRaporPdf(int raporId, {required String scope}) async =>
      pdfs[raporId];

  @override
  Future<void> saveRaporPdf(
    int raporId,
    Uint8List pdfBytes, {
    required String scope,
  }) async {
    pdfs[raporId] = pdfBytes;
  }
}

class _RaporService extends RaporService {
  _RaporService()
    : super(baseUrl: 'https://example.com', tenantApiConfig: _tenant);

  List<dynamic> reports = [];
  Map<String, dynamic> detail = {};
  bool fail = false;
  int detailFetchCount = 0;
  int pdfFetchCount = 0;
  Uint8List pdfBytes = Uint8List.fromList([1, 2, 3]);
  final cursorRequests = <String?>[];

  @override
  Future<Map<String, dynamic>> syncReportList(
    String token, {
    String? cursor,
  }) async {
    cursorRequests.add(cursor);
    if (fail) throw Exception('offline');
    return result;
  }

  Map<String, dynamic> result = {};
  @override
  Future<Map<String, dynamic>> fetchReportDetail(
    String token,
    int raporId,
  ) async {
    detailFetchCount++;
    if (fail) throw Exception('offline');
    return detail;
  }

  @override
  Future<Uint8List> fetchReportPdf(String token, int raporId) async {
    pdfFetchCount++;
    if (fail) throw Exception('offline');
    return pdfBytes;
  }
}

class _BukuStorage extends BukuKomunikasiLocalStorage {
  Map<String, dynamic>? snapshot;
  String? scope;
  bool fresh = false;
  String? cursor;
  int? fullSyncAt;

  @override
  Future<Map<String, dynamic>?> loadBukuKomunikasi({
    required String scope,
  }) async {
    this.scope = scope;
    return snapshot;
  }

  @override
  Future<bool> isBukuKomunikasiFresh({required String scope}) async => fresh;

  @override
  Future<String?> loadCursor({required String scope}) async => cursor;

  @override
  Future<int?> loadFullSyncAt({required String scope}) async => fullSyncAt;

  @override
  Future<void> saveCursor(String value, {required String scope}) async {
    cursor = value;
  }

  @override
  Future<void> saveFullSyncAt(int timestamp, {required String scope}) async {
    fullSyncAt = timestamp;
  }

  @override
  Future<void> saveBukuKomunikasi(
    Map<String, dynamic>? rawData, {
    required String scope,
  }) async {
    this.scope = scope;
    snapshot = rawData == null ? null : Map.from(rawData);
  }
}

class _BukuService extends BukuKomunikasiService {
  _BukuService()
    : super(baseUrl: 'https://example.com', tenantApiConfig: _tenant);

  Map<String, dynamic>? detail = {};
  bool fail = false;
  int fetchCount = 0;

  @override
  Future<Map<String, dynamic>?> fetchBukuKomunikasi(String token) async {
    fetchCount++;
    if (fail) throw Exception('offline');
    return detail;
  }

  @override
  Future<Map<String, dynamic>> syncBukuKomunikasi(
    String token, {
    String? cursor,
  }) async {
    final result = await fetchBukuKomunikasi(token);
    return {
      'items': result?['lines'] ?? <dynamic>[],
      'header_id': result?['id'],
      'student_name': result?['student_name'],
      'kelas': result?['kelas'],
      'tahun_ajaran': result?['tahun_ajaran'],
      'status': result?['status'],
      'next_cursor': 'buku-$fetchCount',
      'full_sync': true,
    };
  }
}

Map<String, dynamic> _report(int id) => {'id': id, 'student_id': 2};
Map<String, dynamic> _assignment(int id, String title) => {
  'id': id,
  'title': title,
  'state': 'published',
};

void main() {
  test(
    'assignment delta upserts and offline fallback retain the scoped snapshot',
    () async {
      final storage = _AssignmentStorage();
      final service = _AssignmentService()
        ..result = {
          'items': [_assignment(1, 'Awal')],
          'removed_ids': <int>[],
          'next_cursor': 'cursor-1',
          'full_sync': true,
        };
      final repository = AssignmentRepository(
        apiService: service,
        localStorage: storage,
      );
      final token = _studentToken();

      expect((await repository.getAssignments(token)).single.title, 'Awal');
      service.result = {
        'items': [_assignment(1, 'Terkini'), _assignment(2, 'Baru')],
        'removed_ids': <int>[],
        'next_cursor': 'cursor-2',
        'full_sync': false,
      };
      expect(
        (await repository.getAssignments(token)).map((item) => item.title),
        ['Terkini', 'Baru'],
      );
      storage.snapshots.values.single['full_sync_at'] = 0;
      service.fail = false;
      service.result = {
        'items': [_assignment(3, 'Rekonsiliasi')],
        'removed_ids': <int>[],
        'next_cursor': 'cursor-3',
        'full_sync': true,
      };
      expect(
        (await repository.getAssignments(token)).map((item) => item.title),
        ['Rekonsiliasi'],
      );
      expect(service.cursorRequests, [null, 'cursor-1', null]);
      service.fail = true;
      expect(
        (await repository.getAssignments(token)).map((item) => item.title),
        ['Rekonsiliasi'],
      );
      expect(storage.snapshots.keys.single, 'school_1_user_2_student_2');
    },
  );

  test(
    'CBT schedule deltas upsert, remove, reconcile, and fall back offline',
    () async {
      final storage = _CbtStorage();
      final service = _CbtService()
        ..schedules = [
          {'id': 1},
        ];
      final repository = CbtRepository(
        apiService: service,
        localStorage: storage,
      );

      expect((await repository.getCbtSchedules(_studentToken())).single.id, 1);
      service
        ..isFullSync = false
        ..deltaSchedules = [
          {'id': 1, 'judul_ujian': 'Updated'},
          {'id': 2},
        ]
        ..removedIds = [3];
      storage.snapshots['school_1_user_2_student_2']!['items'] = [
        {'id': 1},
        {'id': 3},
      ];
      final delta = await repository.getCbtSchedules(_studentToken());
      expect(delta.map((record) => record.id).toSet(), {1, 2});
      expect(delta.firstWhere((record) => record.id == 1).title, 'Updated');
      service.schedules = [
        {'id': 4},
      ];
      storage.snapshots['school_1_user_2_student_2']!['full_sync_at'] = 0;
      service.isFullSync = true;
      expect((await repository.getCbtSchedules(_studentToken())).single.id, 4);
      service.fail = true;
      expect((await repository.getCbtSchedules(_studentToken())).single.id, 4);
      expect(storage.snapshots.keys.single, 'school_1_user_2_student_2');
      expect(service.cursors, [null, 'cbt-1', null, 'cbt-1']);
    },
  );

  test(
    'tagihan refresh replaces the aggregate snapshot and preserves fallback',
    () async {
      final storage = _TagihanStorage();
      final service = _TagihanService()
        ..summary = {'total_invoices': 1, 'invoices': []};
      final repository = TagihanRepository(
        apiService: service,
        localStorage: storage,
      );

      expect((await repository.getTagihan(_token)).totalInvoices, 1);
      service.summary = {'total_invoices': 3, 'invoices': []};
      expect(
        (await repository.getTagihan(_token, forceRefresh: true)).totalInvoices,
        3,
      );
      service.fail = true;
      expect(
        (await repository.getTagihan(_token, forceRefresh: true)).totalInvoices,
        3,
      );
      expect(service.fetchCount, 3);
    },
  );

  test(
    'tagihan force refresh bypasses a fresh cache and replaces its snapshot',
    () async {
      final storage = _TagihanStorage();
      final service = _TagihanService()
        ..summary = {'total_invoices': 1, 'invoices': []};
      final repository = TagihanRepository(
        apiService: service,
        localStorage: storage,
      );

      expect((await repository.getTagihan(_token)).totalInvoices, 1);
      expect(service.fetchCount, 1);

      service.summary = {'total_invoices': 4, 'invoices': []};
      expect(
        (await repository.getTagihan(_token, forceRefresh: true)).totalInvoices,
        4,
      );
      expect(service.fetchCount, 2);

      expect((await repository.getTagihan(_token)).totalInvoices, 4);
      expect(service.fetchCount, 2);
    },
  );

  test(
    'tagihan expired cache refreshes automatically and remains offline fallback',
    () async {
      final storage = _TagihanStorage();
      final service = _TagihanService()
        ..summary = {'total_invoices': 2, 'invoices': []};
      final repository = TagihanRepository(
        apiService: service,
        localStorage: storage,
      );

      expect((await repository.getTagihan(_token)).totalInvoices, 2);
      storage.freshSnapshots.clear();
      service
        ..summary = {'total_invoices': 5, 'invoices': []}
        ..fail = true;

      expect((await repository.getTagihan(_token)).totalInvoices, 2);
      expect(service.fetchCount, 2);
      expect(repository.lastSyncError, contains('offline'));
    },
  );

  test(
    'E-Rapor delta upserts and offline fallback retain the scoped list snapshot',
    () async {
      final storage = _RaporStorage();
      final service = _RaporService()
        ..result = {
          'items': [_report(1)],
          'removed_ids': <int>[],
          'next_cursor': 'rapor-1',
          'full_sync': true,
        };
      final repository = RaporRepository(
        apiService: service,
        localStorage: storage,
      );

      expect((await repository.getReportList(_token)).single.id, 1);
      service.result = {
        'items': [_report(2)],
        'removed_ids': [1],
        'next_cursor': 'rapor-2',
        'full_sync': false,
      };
      expect((await repository.getReportList(_token)).single.id, 1);
      expect(service.cursorRequests, [null]);
      expect(
        (await repository.getReportList(_token, forceRefresh: true)).single.id,
        2,
      );
      service.fail = true;
      expect(
        (await repository.getReportList(_token, forceRefresh: true)).single.id,
        2,
      );
      expect(storage.listScope, 'school_1_user_2');
      storage.snapshot!['full_sync_at'] = 0;
      service.fail = false;
      service.result = {
        'items': [_report(3)],
        'removed_ids': <int>[],
        'next_cursor': 'rapor-3',
        'full_sync': true,
      };
      expect(
        (await repository.getReportList(_token, forceRefresh: true)).single.id,
        3,
      );
      expect(service.cursorRequests, [null, 'rapor-1', 'rapor-2', null]);

      service.detail = {'id': 20, 'student_id': 2, 'student_name': 'Awal'};
      expect(
        (await repository.getReportDetail(_token, 20)).studentName,
        'Awal',
      );
      expect(
        (await repository.getReportDetail(_token, 20)).studentName,
        'Awal',
      );
      expect(service.detailFetchCount, 1);
      service.detail = {'id': 20, 'student_id': 2, 'student_name': 'Terkini'};
      expect(
        (await repository.getReportDetail(
          _token,
          20,
          forceRefresh: true,
        )).studentName,
        'Terkini',
      );
      service.fail = true;
      expect(
        (await repository.getReportDetail(
          _token,
          20,
          forceRefresh: true,
        )).studentName,
        'Terkini',
      );
      expect(storage.detailScope, 'school_1_user_2');

      service.fail = false;
      expect(await repository.getReportPdf(_token, 20), [1, 2, 3]);
      service.pdfBytes = Uint8List.fromList([4, 5]);
      expect(await repository.getReportPdf(_token, 20), [1, 2, 3]);
      expect(service.pdfFetchCount, 1);
      expect(await repository.getReportPdf(_token, 20, forceRefresh: true), [
        4,
        5,
      ]);
      expect(service.pdfFetchCount, 2);
    },
  );

  test(
    'Buku Komunikasi replaces aggregate snapshot and uses cached data offline',
    () async {
      final storage = _BukuStorage();
      final service = _BukuService()
        ..detail = {'id': 4, 'student_name': 'Siswa Baru', 'lines': []};
      final repository = BukuKomunikasiRepository(
        apiService: service,
        localStorage: storage,
      );

      expect(
        (await repository.getBukuKomunikasi(_token))?.studentName,
        'Siswa Baru',
      );
      service.detail = {'id': 5, 'student_name': 'Siswa Terkini', 'lines': []};
      storage.fresh = true;
      expect(
        (await repository.getBukuKomunikasi(_token))?.studentName,
        'Siswa Baru',
      );
      expect(
        (await repository.getBukuKomunikasi(
          _token,
          forceRefresh: true,
        ))?.studentName,
        'Siswa Terkini',
      );
      service.fail = true;
      expect(
        (await repository.getBukuKomunikasi(
          _token,
          forceRefresh: true,
        ))?.studentName,
        'Siswa Terkini',
      );
      expect(service.fetchCount, 3);
      expect(storage.scope, 'school_1_user_2');
    },
  );
}
