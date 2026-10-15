import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/kehadiran/local/attendance_local_storage.dart';
import 'package:flutter_application_1/features/kehadiran/models/attendance_record.dart';
import 'package:flutter_application_1/features/kehadiran/repositories/attendance_repository.dart';
import 'package:flutter_application_1/features/kehadiran/services/attendance_service.dart';
import 'package:flutter_application_1/features/kehadiran/viewmodel/attendance_viewmodel.dart';
import 'package:flutter_application_1/services/tenant_api_config.dart';

class _DelayedAttendanceRepository extends AttendanceRepository {
  _DelayedAttendanceRepository()
    : super(
        apiService: AttendanceService(
          baseUrl: 'https://example.test/api/v1',
          tenantApiConfig: TenantApiConfig(),
        ),
        localStorage: AttendanceLocalStorage(),
      );

  List<AttendanceRecord>? cachedRecords;
  Future<List<AttendanceRecord>>? refreshResult;

  @override
  Future<List<AttendanceRecord>?> loadCachedAttendanceHistory(
    String token,
  ) async => cachedRecords;

  @override
  Future<List<AttendanceRecord>> getAttendanceHistory(
    String token, {
    bool forceRefresh = false,
  }) => refreshResult!;
}

AttendanceRecord _record() => AttendanceRecord(
  id: 10,
  studentName: 'Siswa',
  kelas: 'Kelas 1',
  rombel: 'A',
  hadir: 1,
  sakit: 0,
  izin: 0,
  alpha: 0,
  status: 'hadir',
  remark: '',
  date: DateTime(2026, 10, 1),
);

AttendanceRecord _olderRecord() => AttendanceRecord(
  id: 11,
  studentName: 'Siswa',
  kelas: 'Kelas 1',
  rombel: 'A',
  hadir: 1,
  sakit: 0,
  izin: 0,
  alpha: 0,
  status: 'hadir',
  remark: '',
  date: DateTime(DateTime.now().year, 1, 1),
);

void main() {
  test(
    'defaults to the current month when attendance has older records',
    () async {
      final repository = _DelayedAttendanceRepository()
        ..cachedRecords = [_olderRecord()]
        ..refreshResult = Future.value([_olderRecord()]);
      final viewModel = AttendanceViewModel(repository: repository);

      await viewModel.fetchAttendance('token');

      expect(
        viewModel.activeMonthLabel,
        viewModel.monthLabelFor(DateTime.now()),
      );
      expect(
        viewModel.availableMonths,
        contains(viewModel.monthLabelFor(DateTime.now())),
      );
      viewModel.dispose();
    },
  );

  test(
    'shows cached attendance before the network refresh completes',
    () async {
      final repository = _DelayedAttendanceRepository()
        ..cachedRecords = [_record()];
      final refresh = Completer<List<AttendanceRecord>>();
      repository.refreshResult = refresh.future;
      final viewModel = AttendanceViewModel(repository: repository);

      final fetch = viewModel.fetchAttendance('token');
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.hasLoadedData, isTrue);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.isRefreshing, isTrue);
      expect(viewModel.filteredRecords.single.id, 10);

      refresh.completeError(Exception('offline'));
      await fetch;

      expect(viewModel.isRefreshing, isFalse);
      expect(viewModel.filteredRecords.single.id, 10);
      expect(viewModel.errorMessage, isNull);
      viewModel.dispose();
    },
  );

  test('shows loading until first refresh when no cache exists', () async {
    final repository = _DelayedAttendanceRepository()..cachedRecords = null;
    final refresh = Completer<List<AttendanceRecord>>();
    repository.refreshResult = refresh.future;
    final viewModel = AttendanceViewModel(repository: repository);

    final fetch = viewModel.fetchAttendance('token');
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.hasLoadedData, isFalse);
    expect(viewModel.isLoading, isTrue);
    expect(viewModel.isRefreshing, isFalse);

    refresh.complete([_record()]);
    await fetch;

    expect(viewModel.hasLoadedData, isTrue);
    expect(viewModel.filteredRecords.single.id, 10);
    viewModel.dispose();
  });
}
