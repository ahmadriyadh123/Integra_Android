import 'dart:convert';

import '../local/calendar_local_storage.dart';
import '../models/calendar_model.dart';
import '../services/calendar_service.dart';

class CalendarRepository {
  final CalendarService apiService;
  final CalendarLocalStorage localStorage;

  CalendarRepository({
    required this.apiService,
    required this.localStorage,
  });

  /// Mengambil data kalender dengan strategi Cache-First dan fallback Offline.
  Future<List<CalendarItem>> getCalendars(String token, {bool forceRefresh = false}) async {
    final cacheScope = cacheScopeForToken(token);

    // 1. Coba load dari cache Hive terlebih dahulu (kecuali dipaksa refresh)
    if (!forceRefresh) {
      try {
        final cachedList = await localStorage.loadCalendars(
          cacheScope: cacheScope,
        );
        if (cachedList != null) {
          return cachedList
              .map((item) => CalendarItem.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
        }
      } catch (_) {
        // Abaikan error cache, langsung fetch dari API
      }
    }

    // 2. Ambil data dari API jika cache kosong/expired
    try {
      final data = await apiService.fetchCalendars(token);
      final List<dynamic> rawList = data['calendars'] as List<dynamic>? ?? [];
      
      // Simpan data mentah terbaru ke Hive untuk cache berikutnya
      await localStorage.saveCalendars(rawList, cacheScope: cacheScope);
      
      return rawList
          .map((item) => CalendarItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      // 3. Fallback jika jaringan/API error: coba baca cache terakhir meskipun expired
      try {
        final cachedList = await localStorage.loadCalendars(
          cacheScope: cacheScope,
        );
        if (cachedList != null) {
          return cachedList
              .map((item) => CalendarItem.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
        }
      } catch (_) {}
      
      rethrow;
    }
  }

  String cacheScopeForToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException('Token login tidak valid untuk cache kalender.');
    }

    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map<String, dynamic>) {
        throw const FormatException();
      }

      final schoolId = _parseId(payload['school_id']);
      final userId = _parseId(payload['uid']);
      final courseId = _parseId(payload['course_id']);
      if (schoolId == null || userId == null || courseId == null) {
        throw const FormatException();
      }
      return 'school_${schoolId}_user_${userId}_course_$courseId';
    } on FormatException {
      throw const FormatException(
        'Token login tidak memiliki identitas sekolah, pengguna, dan kelas yang valid.',
      );
    }
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
