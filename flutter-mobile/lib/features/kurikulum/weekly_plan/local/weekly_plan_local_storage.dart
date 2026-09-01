import 'package:hive_flutter/hive_flutter.dart';

/// Service untuk menyimpan dan membaca cache data Weekly Plan menggunakan Hive.
class WeeklyPlanLocalStorage {
  static const String boxName = 'weekly_plan_cache_box';
  static const String keyList = 'weekly_plan_list';
  static const String keyTimestamp = 'weekly_plan_list_ts';
  
  // Waktu kedaluwarsa cache (TTL): 1 Jam
  static const Duration cacheTtl = Duration(hours: 1);

  /// Inisialisasi Box Hive untuk Weekly Plan.
  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  /// Simpan daftar weekly plan ke Hive.
  Future<void> saveWeeklyPlanList(List<dynamic> plans) async {
    final box = await _getBox();
    await box.put(keyList, plans);
    await box.put(keyTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  /// Baca daftar weekly plan dari Hive.
  /// Kembalikan null jika data kedaluwarsa atau tidak ada di cache.
  Future<List<dynamic>?> loadWeeklyPlanList() async {
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

    final plans = box.get(keyList);
    if (plans is List) {
      return plans;
    }
    return null;
  }

  /// Hapus seluruh cache data weekly plan.
  Future<void> clearCache() async {
    final box = await _getBox();
    await box.delete(keyList);
    await box.delete(keyTimestamp);
  }
}
