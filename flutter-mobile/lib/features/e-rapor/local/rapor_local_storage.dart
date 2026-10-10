import 'package:hive_flutter/hive_flutter.dart';

/// Service untuk menyimpan dan membaca cache data E-Rapor menggunakan Hive.
class RaporLocalStorage {
  static const String boxName = 'rapor_cache_box';
  static const String keyList = 'rapor_list';
  static const String keyListTimestamp = 'rapor_list_ts';

  // Waktu kedaluwarsa cache (TTL): 1 Jam
  static const Duration cacheTtl = Duration(hours: 1);
  static const Duration fullSyncInterval = Duration(hours: 24);

  /// Inisialisasi Box Hive untuk E-Rapor.
  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  /// Mendapatkan key dinamis untuk detail rapor berdasarkan ID
  String _getDetailKey(int raporId, String scope) =>
      'rapor_detail_${scope}_$raporId';

  /// Simpan daftar rapor ke Hive.
  String _listKey(String scope) => '${keyList}_$scope';

  Future<void> saveRaporList(
    List<dynamic> raporList, {
    required String scope,
    String? cursor,
    int? fullSyncAt,
  }) async {
    final box = await _getBox();
    final key = _listKey(scope);
    final previous = box.get(key);
    await box.put(key, {
      'items': raporList,
      'cursor': cursor ?? (previous is Map ? previous['cursor'] : null),
      'full_sync_at':
          fullSyncAt ?? (previous is Map ? previous['full_sync_at'] : null),
      'saved_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<Map<String, dynamic>?> loadRaporListSnapshot({
    required String scope,
  }) async {
    final value = (await _getBox()).get(_listKey(scope));
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  /// Baca daftar rapor dari Hive.
  /// Kembalikan null jika data kedaluwarsa atau tidak ada di cache.
  Future<List<dynamic>?> loadRaporList({required String scope}) async {
    final box = await _getBox();
    final snapshot = box.get(_listKey(scope));
    final raporList = snapshot is Map ? snapshot['items'] : null;
    if (raporList is List) {
      return raporList;
    }
    return null;
  }

  /// Simpan detail rapor ke Hive berdasarkan raporId.
  Future<void> saveRaporDetail(
    int raporId,
    Map<String, dynamic> detail, {
    required String scope,
  }) async {
    final box = await _getBox();
    await box.put(_getDetailKey(raporId, scope), {
      'detail': detail,
      'saved_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Baca detail rapor dari Hive berdasarkan raporId.
  /// Kembalikan null jika data kedaluwarsa atau tidak ada di cache.
  Future<Map<String, dynamic>?> loadRaporDetail(
    int raporId, {
    required String scope,
  }) async {
    final box = await _getBox();
    final snapshot = box.get(_getDetailKey(raporId, scope));
    final detail = snapshot is Map ? snapshot['detail'] : null;
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
  Future<void> clearRaporDetailCache(
    int raporId, {
    required String scope,
  }) async {
    final box = await _getBox();
    await box.delete(_getDetailKey(raporId, scope));
  }

  /// Hapus seluruh cache E-Rapor.
  Future<void> clearAllCache() async {
    final box = await _getBox();
    await box.clear();
  }
}
