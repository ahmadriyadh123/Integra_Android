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

  /// Menyimpan data ringkasan tagihan ke cache lokal Hive.
  Future<void> saveTagihanSummary(
    String? paymentState,
    Map<String, dynamic> data, {
    required String scope,
  }) async {
    final box = await _getBox();
    await box.put(_getCacheKey(paymentState, scope), {
      'data': data,
      'saved_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Membaca data ringkasan tagihan dari cache lokal Hive.
  /// Mengembalikan null jika data kedaluwarsa atau tidak ditemukan.
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

  /// Menghapus cache berdasarkan status pembayaran tertentu.
  Future<void> clearCache(String? paymentState, {required String scope}) async {
    final box = await _getBox();
    await box.delete(_getCacheKey(paymentState, scope));
  }

  /// Menghapus seluruh cache tagihan.
  Future<void> clearAllCache({required String scope}) async {
    final box = await _getBox();
    final prefix = 'tagihan_summary_${scope}_';
    for (final key in box.keys.where((key) => key.toString().startsWith(prefix))) {
      await box.delete(key);
    }
  }
}
