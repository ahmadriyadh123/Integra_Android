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
  String _key(String scope) {
    if (scope.trim().isEmpty) {
      throw ArgumentError.value(scope, 'scope', 'Tidak boleh kosong');
    }
    return '${keySchedules}_$scope';
  }

  Future<void> saveCbtSchedules(
    List<dynamic> schedules, {
    required String scope,
    String? cursor,
    int? fullSyncAt,
  }) async {
    final box = await _getBox();
    await box.put(_key(scope), {
      'items': schedules,
      'saved_at': DateTime.now().millisecondsSinceEpoch,
      'cursor': cursor,
      'full_sync_at': fullSyncAt,
    });
  }

  /// Baca daftar jadwal ujian dari Hive.
  /// Kembalikan null jika data kedaluwarsa atau tidak ada di cache.
  Future<List<dynamic>?> loadCbtSchedules({required String scope}) async {
    final snapshot = await loadCbtSnapshot(scope: scope);
    final schedules = snapshot?['items'];
    return schedules is List ? schedules : null;
  }

  Future<Map<String, dynamic>?> loadCbtSnapshot({required String scope}) async {
    final box = await _getBox();
    final value = box.get(_key(scope));
    if (value is Map && value['items'] is List) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  /// Hapus seluruh cache data CBT.
  Future<void> clearCache({required String scope}) async {
    final box = await _getBox();
    await box.delete(_key(scope));
  }
}
