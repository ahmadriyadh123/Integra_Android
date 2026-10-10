import 'dart:convert';

import '../local/attendance_local_storage.dart';
import '../models/attendance_record.dart';
import '../services/attendance_service.dart';

class AttendanceRepository {
  final AttendanceService apiService;
  final AttendanceLocalStorage localStorage;
  String? lastSyncError;

  AttendanceRepository({
    required this.apiService,
    required this.localStorage,
  });

  Future<List<AttendanceRecord>> getAttendanceHistory(
    String token, {
    bool forceRefresh = false,
  }) async {
    final scope = cacheScopeForToken(token);
    final snapshot = await localStorage.loadSnapshot(scope: scope);
    final rawCached = snapshot?['items'];
    final cached = rawCached is List
        ? rawCached
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : null;
    final fullSyncAt = snapshot?['full_sync_at'];
    final fullSyncDue = fullSyncAt is! int ||
        DateTime.now().difference(
              DateTime.fromMillisecondsSinceEpoch(fullSyncAt),
            ) >=
            const Duration(hours: 24);
    final fullSync = forceRefresh || cached == null || fullSyncDue;

    try {
      final result = await apiService.syncAttendanceHistory(
        token,
        cursor: fullSync ? null : snapshot?['cursor'] as String?,
      );
      final rawItems = result['items'];
      final nextCursor = result['next_cursor'];
      final isFullSync = result['full_sync'];
      final rawRemovedIds = result['removed_ids'];
      if (rawItems is! List ||
          nextCursor is! String ||
          nextCursor.isEmpty ||
          isFullSync is! bool ||
          rawRemovedIds is! List ||
          (fullSync && !isFullSync)) {
        throw const FormatException(
          'Respons sinkronisasi presensi tidak lengkap.',
        );
      }

      final merged = <int, Map<String, dynamic>>{};
      if (!isFullSync && cached != null) {
        for (final item in cached) {
          final id = _parseId(item['id']);
          if (id == null) {
            throw const FormatException('ID cache presensi tidak valid.');
          }
          merged[id] = item;
        }
      }
      for (final value in rawRemovedIds) {
        final id = _parseId(value);
        if (id == null) {
          throw const FormatException('ID presensi yang dihapus tidak valid.');
        }
        merged.remove(id);
      }
      for (final value in rawItems) {
        if (value is! Map) {
          throw const FormatException('Record presensi tidak valid.');
        }
        final item = Map<String, dynamic>.from(value);
        final id = _parseId(item['id']);
        if (id == null) {
          throw const FormatException('ID presensi tidak valid.');
        }
        merged[id] = item;
      }

      final items = merged.values.toList();
      final nextFullSyncAt = isFullSync
          ? DateTime.now().millisecondsSinceEpoch
          : (fullSyncAt is int
                ? fullSyncAt
                : DateTime.now().millisecondsSinceEpoch);
      await localStorage.saveSnapshot(
        scope: scope,
        items: items,
        cursor: nextCursor,
        fullSyncAt: nextFullSyncAt,
      );
      lastSyncError = null;
      return items.map(AttendanceRecord.fromJson).toList();
    } catch (error) {
      lastSyncError = error.toString();
      if (cached != null) {
        return cached.map(AttendanceRecord.fromJson).toList();
      }
      rethrow;
    }
  }

  String cacheScopeForToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException('Token login tidak valid untuk cache presensi.');
    }
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Klaim token presensi tidak valid.');
    }
    final school = _parseId(payload['school_id']);
    final user = _parseId(payload['uid']);
    final student = _parseId(payload['student_id']);
    final course = _parseId(payload['course_id']);
    if (school == null || user == null) {
      throw const FormatException(
        'Token tidak memiliki identitas sekolah dan pengguna.',
      );
    }
    return 'school_${school}_user_${user}_student_${student ?? 0}_course_${course ?? 0}';
  }

  int? _parseId(dynamic value) {
    if (value is int && value > 0) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }
}
