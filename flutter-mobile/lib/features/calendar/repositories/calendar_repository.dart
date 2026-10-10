import 'dart:convert';

import '../local/calendar_local_storage.dart';
import '../models/calendar_model.dart';
import '../services/calendar_service.dart';

class CalendarRepository {
  final CalendarService apiService;
  final CalendarLocalStorage localStorage;
  String? lastSyncError;

  CalendarRepository({
    required this.apiService,
    required this.localStorage,
  });

  Future<List<CalendarItem>> getCalendars(
    String token, {
    bool forceRefresh = false,
  }) async {
    final scope = cacheScopeForToken(token);
    final snapshot = await localStorage.loadSnapshot(cacheScope: scope);
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
      final result = await apiService.syncCalendars(
        token,
        cursor: fullSync ? null : snapshot?['cursor'] as String?,
      );
      final rawItems = result['items'];
      final rawRemovedIds = result['removed_ids'];
      final cursor = result['next_cursor'];
      final isFullSync = result['full_sync'];
      if (rawItems is! List ||
          rawRemovedIds is! List ||
          cursor is! String ||
          cursor.isEmpty ||
          isFullSync is! bool ||
          (fullSync && !isFullSync)) {
        throw const FormatException(
          'Respons sinkronisasi kalender tidak lengkap.',
        );
      }

      final merged = <int, Map<String, dynamic>>{};
      if (!isFullSync && cached != null) {
        for (final item in cached) {
          final id = _parseId(item['id']);
          if (id == null) {
            throw const FormatException('ID cache kalender tidak valid.');
          }
          merged[id] = item;
        }
      }
      for (final value in rawRemovedIds) {
        final id = _parseId(value);
        if (id == null) {
          throw const FormatException('ID kalender yang dihapus tidak valid.');
        }
        merged.remove(id);
      }
      for (final value in rawItems) {
        if (value is! Map) {
          throw const FormatException('Record kalender tidak valid.');
        }
        final item = Map<String, dynamic>.from(value);
        final id = _parseId(item['id']);
        if (id == null) {
          throw const FormatException('ID kalender tidak valid.');
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
        cacheScope: scope,
        items: items,
        cursor: cursor,
        fullSyncAt: nextFullSyncAt,
      );
      lastSyncError = null;
      return items.map(CalendarItem.fromJson).toList();
    } catch (error) {
      lastSyncError = error.toString();
      if (cached != null) return cached.map(CalendarItem.fromJson).toList();
      rethrow;
    }
  }

  String cacheScopeForToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException('Token login tidak valid untuk cache kalender.');
    }
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Klaim token kalender tidak valid.');
    }
    final schoolId = _parseId(payload['school_id']);
    final userId = _parseId(payload['uid']);
    final courseId = _parseId(payload['course_id']);
    if (schoolId == null || userId == null || courseId == null) {
      throw const FormatException(
        'Token tidak memiliki identitas sekolah, pengguna, dan kelas.',
      );
    }
    return 'school_${schoolId}_user_${userId}_course_$courseId';
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
