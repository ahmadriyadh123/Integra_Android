import 'package:hive_flutter/hive_flutter.dart';

/// Service untuk menyimpan dan membaca cache data Tagihan (Billing) menggunakan Hive.
/// Menyediakan local caching dengan validasi kadaluwarsa (TTL 1 Jam).
class TagihanLocalStorage {
  static const String boxName = 'tagihan_cache_box';
  
  // Waktu kadaluwarsa cache (TTL): 1 Jam
  static const Duration cacheTtl = Duration(hours: 1);

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  /// Mendapatkan key dinamis berdasarkan status pembayaran (all, paid, not_paid, dll.)
  String _getCacheKey(String? paymentState, String scope) {
    return 'tagihan_summary_${scope}_${paymentState ?? 'all'}';
  }

  String _getCursorKey(String scope) => 'tagihan_cursor_$scope';
  String _getFullSyncAtKey(String scope) => 'tagihan_full_sync_at_$scope';

  /// Interval full sync: setiap 24 jam backend ditarik penuh untuk menangkap
  /// data yang hilang dari delta (mis. perubahan tanpa update write_date).
  static const Duration fullSyncInterval = Duration(hours: 24);

  /// Menyimpan data ringkasan tagihan ke cache lokal Hive.
  Future<void> saveTagihanSummary(
    String? paymentState,
    Map<String, dynamic> data, {
    required String scope,
    String? cursor,
  }) async {
    final box = await _getBox();
    await box.put(_getCacheKey(paymentState, scope), {
      'data': data,
      'saved_at': DateTime.now().millisecondsSinceEpoch,
    });
    if (cursor != null) {
      await box.put(_getCursorKey(scope), cursor);
    }
  }

  Future<String?> loadCursor(String scope) async {
    final box = await _getBox();
    final value = box.get(_getCursorKey(scope));
    return value is String ? value : null;
  }

  Future<void> saveCursor(String scope, String cursor) async {
    final box = await _getBox();
    await box.put(_getCursorKey(scope), cursor);
  }

  /// Timestamp (ms) sinkronisasi penuh terakhir. Dipakai untuk memutuskan kapan
  /// harus full sync lagi, alih-alih delta sync berbasis cursor.
  Future<int?> loadFullSyncAt(String scope) async {
    final box = await _getBox();
    final value = box.get(_getFullSyncAtKey(scope));
    return value is int ? value : null;
  }

  Future<void> saveFullSyncAt(String scope, int timestamp) async {
    final box = await _getBox();
    await box.put(_getFullSyncAtKey(scope), timestamp);
  }

  /// Membaca data ringkasan tagihan dari cache lokal Hive.
  /// Mengembalikan null jika data tidak ditemukan atau format cache tidak valid.
  Future<Map<String, dynamic>?> loadTagihanSummary(
    String? paymentState, {
    required String scope,
  }) async {
    final box = await _getBox();
    final snapshot = box.get(_getCacheKey(paymentState, scope));
    final rawData = snapshot is Map ? snapshot['data'] : null;
    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }
    return null;
  }

  /// Mengembalikan true jika cache masih berada dalam TTL satu jam.
  Future<bool> isTagihanSummaryFresh(
    String? paymentState, {
    required String scope,
  }) async {
    final box = await _getBox();
    final snapshot = box.get(_getCacheKey(paymentState, scope));
    final savedAt = snapshot is Map ? snapshot['saved_at'] : null;
    if (savedAt is! int) return false;

    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(savedAt),
    );
    return age >= Duration.zero && age < cacheTtl;
  }

  /// Menghapus cache berdasarkan status pembayaran tertentu.
  Future<void> clearCache(String? paymentState, {required String scope}) async {
    final box = await _getBox();
    await box.delete(_getCacheKey(paymentState, scope));
  }

  /// Menghapus seluruh cache tagihan (summary + cursor + full sync ts).
  Future<void> clearAllCache({required String scope}) async {
    final box = await _getBox();
    final prefix = 'tagihan_summary_${scope}_';
    for (final key in box.keys.where((key) => key.toString().startsWith(prefix))) {
      await box.delete(key);
    }
    await box.delete(_getCursorKey(scope));
    await box.delete(_getFullSyncAtKey(scope));
  }
}
