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
    // 1. Coba load dari cache Hive terlebih dahulu (kecuali dipaksa refresh)
    if (!forceRefresh) {
      try {
        final cachedList = await localStorage.loadCalendars();
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
      await localStorage.saveCalendars(rawList);
      
      return rawList
          .map((item) => CalendarItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      // 3. Fallback jika jaringan/API error: coba baca cache terakhir meskipun expired
      try {
        final cachedList = await localStorage.loadCalendars();
        if (cachedList != null) {
          return cachedList
              .map((item) => CalendarItem.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
        }
      } catch (_) {}
      
      rethrow;
    }
  }
}
