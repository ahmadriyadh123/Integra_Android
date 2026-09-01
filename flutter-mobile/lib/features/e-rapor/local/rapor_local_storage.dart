import 'package:hive_flutter/hive_flutter.dart';

/// Service untuk menyimpan dan membaca cache data E-Rapor menggunakan Hive.
class RaporLocalStorage {
  static const String boxName = 'rapor_cache_box';
  static const String keyList = 'rapor_list';
  static const String keyListTimestamp = 'rapor_list_ts';
  
  // Waktu kedaluwarsa cache (TTL): 1 Jam
  static const Duration cacheTtl = Duration(hours: 1);

  /// Inisialisasi Box Hive untuk E-Rapor.
  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  /// Mendapatkan key dinamis untuk detail rapor berdasarkan ID
  String _getDetailKey(int raporId) => 'rapor_detail_$raporId';
  String _getDetailTimestampKey(int raporId) => 'rapor_detail_ts_$raporId';

  /// Simpan daftar rapor ke Hive.
  Future<void> saveRaporList(List<dynamic> raporList) async {
    final box = await _getBox();
    await box.put(keyList, raporList);
    await box.put(keyListTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  /// Baca daftar rapor dari Hive.
  /// Kembalikan null jika data kedaluwarsa atau tidak ada di cache.
  Future<List<dynamic>?> loadRaporList() async {
    final box = await _getBox();
    
    // Cek kesegaran cache
    final ts = box.get(keyListTimestamp) as int?;
    if (ts == null) return null;

    final savedTime = DateTime.fromMillisecondsSinceEpoch(ts);
    final isExpired = DateTime.now().difference(savedTime) > cacheTtl;
    
    if (isExpired) {
      await clearRaporListCache();
      return null;
    }

    final raporList = box.get(keyList);
    if (raporList is List) {
      return raporList;
    }
    return null;
  }

  /// Simpan detail rapor ke Hive berdasarkan raporId.
  Future<void> saveRaporDetail(int raporId, Map<String, dynamic> detail) async {
    final box = await _getBox();
    final key = _getDetailKey(raporId);
    final tsKey = _getDetailTimestampKey(raporId);
    
    await box.put(key, detail);
    await box.put(tsKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Baca detail rapor dari Hive berdasarkan raporId.
  /// Kembalikan null jika data kedaluwarsa atau tidak ada di cache.
  Future<Map<String, dynamic>?> loadRaporDetail(int raporId) async {
    final box = await _getBox();
    final key = _getDetailKey(raporId);
    final tsKey = _getDetailTimestampKey(raporId);

    // Cek kesegaran cache
    final ts = box.get(tsKey) as int?;
    if (ts == null) return null;

    final savedTime = DateTime.fromMillisecondsSinceEpoch(ts);
    final isExpired = DateTime.now().difference(savedTime) > cacheTtl;

    if (isExpired) {
      await clearRaporDetailCache(raporId);
      return null;
    }

    final detail = box.get(key);
    if (detail is Map) {
      return Map<String, dynamic>.from(detail);
    }
    return null;
  }

  /// Hapus cache daftar rapor.
  Future<void> clearRaporListCache() async {
    final box = await _getBox();
    await box.delete(keyList);
    await box.delete(keyListTimestamp);
  }

  /// Hapus cache detail rapor berdasarkan ID.
  Future<void> clearRaporDetailCache(int raporId) async {
    final box = await _getBox();
    final key = _getDetailKey(raporId);
    final tsKey = _getDetailTimestampKey(raporId);
    
    await box.delete(key);
    await box.delete(tsKey);
  }

  /// Hapus seluruh cache E-Rapor.
  Future<void> clearAllCache() async {
    final box = await _getBox();
    await box.clear();
  }
}
