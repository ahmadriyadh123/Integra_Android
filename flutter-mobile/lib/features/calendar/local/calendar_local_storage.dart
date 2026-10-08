import 'package:hive_flutter/hive_flutter.dart';

/// Service untuk menyimpan dan membaca cache data Kalender Akademik menggunakan Hive.
class CalendarLocalStorage {
  static const String boxName = 'calendar_cache_box';
  static const String _keyListPrefix = 'calendar_list';
  static const String _keyTimestampPrefix = 'calendar_ts';
  
  // Waktu kedaluwarsa cache (TTL): 1 Jam
  static const Duration cacheTtl = Duration(hours: 1);

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  /// Simpan list data kalender mentah (List of Maps) ke Hive.
  String _scopedKey(String prefix, String cacheScope) {
    if (cacheScope.trim().isEmpty) {
      throw ArgumentError.value(cacheScope, 'cacheScope', 'Tidak boleh kosong');
    }
    return '${prefix}_$cacheScope';
  }

  Future<void> saveCalendars(
    List<dynamic> rawData, {
    required String cacheScope,
  }) async {
    final box = await _getBox();
    await box.put(_scopedKey(_keyListPrefix, cacheScope), rawData);
    await box.put(
      _scopedKey(_keyTimestampPrefix, cacheScope),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Baca list data kalender dari Hive.
  /// Kembalikan null jika data kedaluwarsa (lebih dari 1 jam) atau tidak ada di cache.
  Future<List<dynamic>?> loadCalendars({required String cacheScope}) async {
    final box = await _getBox();
    
    // Cek kesegaran cache (Timestamp)
    final ts = box.get(_scopedKey(_keyTimestampPrefix, cacheScope)) as int?;
    if (ts == null) return null;

    final savedTime = DateTime.fromMillisecondsSinceEpoch(ts);
    final isExpired = DateTime.now().difference(savedTime) > cacheTtl;
    
    if (isExpired) {
      // Hapus data cache jika sudah kadaluwarsa
      await clearCache(cacheScope: cacheScope);
      return null;
    }

    final rawData = box.get(_scopedKey(_keyListPrefix, cacheScope));
    if (rawData is List) {
      return rawData;
    }
    return null;
  }

  /// Hapus seluruh cache data kalender.
  Future<void> clearCache({required String cacheScope}) async {
    final box = await _getBox();
    await box.delete(_scopedKey(_keyListPrefix, cacheScope));
    await box.delete(_scopedKey(_keyTimestampPrefix, cacheScope));
  }
}
