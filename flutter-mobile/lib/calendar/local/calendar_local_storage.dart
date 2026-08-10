import 'package:hive_flutter/hive_flutter.dart';

/// Service untuk menyimpan dan membaca cache data Kalender Akademik menggunakan Hive.
class CalendarLocalStorage {
  static const String boxName = 'calendar_cache_box';
  static const String keyList = 'calendar_list';
  static const String keyTimestamp = 'calendar_ts';
  
  // Waktu kedaluwarsa cache (TTL): 1 Jam
  static const Duration cacheTtl = Duration(hours: 1);

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  /// Simpan list data kalender mentah (List of Maps) ke Hive.
  Future<void> saveCalendars(List<dynamic> rawData) async {
    final box = await _getBox();
    await box.put(keyList, rawData);
    await box.put(keyTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  /// Baca list data kalender dari Hive.
  /// Kembalikan null jika data kedaluwarsa (lebih dari 1 jam) atau tidak ada di cache.
  Future<List<dynamic>?> loadCalendars() async {
    final box = await _getBox();
    
    // Cek kesegaran cache (Timestamp)
    final ts = box.get(keyTimestamp) as int?;
    if (ts == null) return null;

    final savedTime = DateTime.fromMillisecondsSinceEpoch(ts);
    final isExpired = DateTime.now().difference(savedTime) > cacheTtl;
    
    if (isExpired) {
      // Hapus data cache jika sudah kadaluwarsa
      await clearCache();
      return null;
    }

    final rawData = box.get(keyList);
    if (rawData is List) {
      return rawData;
    }
    return null;
  }

  /// Hapus seluruh cache data kalender.
  Future<void> clearCache() async {
    final box = await _getBox();
    await box.delete(keyList);
    await box.delete(keyTimestamp);
  }
}
