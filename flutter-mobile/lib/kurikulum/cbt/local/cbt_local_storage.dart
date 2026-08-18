import 'package:hive_flutter/hive_flutter.dart';

/// Service untuk menyimpan dan membaca cache data CBT (Ujian) menggunakan Hive.
class CbtLocalStorage {
  static const String boxName = 'cbt_cache_box';
  static const String keySchedules = 'cbt_schedules';
  static const String keyTimestamp = 'cbt_schedules_ts';
  
  // Waktu kedaluwarsa cache (TTL): 1 Jam
  static const Duration cacheTtl = Duration(hours: 1);

  /// Inisialisasi Box Hive untuk CBT.
  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  /// Simpan daftar jadwal ujian ke Hive.
  Future<void> saveCbtSchedules(List<dynamic> schedules) async {
    final box = await _getBox();
    await box.put(keySchedules, schedules);
    await box.put(keyTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  /// Baca daftar jadwal ujian dari Hive.
  /// Kembalikan null jika data kedaluwarsa atau tidak ada di cache.
  Future<List<dynamic>?> loadCbtSchedules() async {
    final box = await _getBox();
    
    // Cek kesegaran cache
    final ts = box.get(keyTimestamp) as int?;
    if (ts == null) return null;

    final savedTime = DateTime.fromMillisecondsSinceEpoch(ts);
    final isExpired = DateTime.now().difference(savedTime) > cacheTtl;
    
    if (isExpired) {
      await clearCache();
      return null;
    }

    final schedules = box.get(keySchedules);
    if (schedules is List) {
      return schedules;
    }
    return null;
  }

  /// Hapus seluruh cache data CBT.
  Future<void> clearCache() async {
    final box = await _getBox();
    await box.delete(keySchedules);
    await box.delete(keyTimestamp);
  }
}
