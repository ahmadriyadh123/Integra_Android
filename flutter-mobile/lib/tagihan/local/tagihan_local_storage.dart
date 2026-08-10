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
  String _getCacheKey(String? paymentState) {
    return 'tagihan_summary_${paymentState ?? 'all'}';
  }

  String _getTimestampKey(String? paymentState) {
    return 'tagihan_summary_ts_${paymentState ?? 'all'}';
  }

  /// Menyimpan data ringkasan tagihan ke cache lokal Hive.
  Future<void> saveTagihanSummary(String? paymentState, Map<String, dynamic> data) async {
    final box = await _getBox();
    final cacheKey = _getCacheKey(paymentState);
    final tsKey = _getTimestampKey(paymentState);
    
    await box.put(cacheKey, data);
    await box.put(tsKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Membaca data ringkasan tagihan dari cache lokal Hive.
  /// Mengembalikan null jika data kedaluwarsa atau tidak ditemukan.
  Future<Map<String, dynamic>?> loadTagihanSummary(String? paymentState) async {
    final box = await _getBox();
    final cacheKey = _getCacheKey(paymentState);
    final tsKey = _getTimestampKey(paymentState);

    // Cek kesegaran cache
    final ts = box.get(tsKey) as int?;
    if (ts == null) return null;

    final savedTime = DateTime.fromMillisecondsSinceEpoch(ts);
    final isExpired = DateTime.now().difference(savedTime) > cacheTtl;

    if (isExpired) {
      await clearCache(paymentState);
      return null;
    }

    final rawData = box.get(cacheKey);
    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }
    return null;
  }

  /// Menghapus cache berdasarkan status pembayaran tertentu.
  Future<void> clearCache(String? paymentState) async {
    final box = await _getBox();
    final cacheKey = _getCacheKey(paymentState);
    final tsKey = _getTimestampKey(paymentState);
    
    await box.delete(cacheKey);
    await box.delete(tsKey);
  }

  /// Menghapus seluruh cache tagihan.
  Future<void> clearAllCache() async {
    final box = await _getBox();
    await box.clear();
  }
}
