import 'package:hive_flutter/hive_flutter.dart';

/// Service untuk menyimpan dan membaca cache data Buku Komunikasi menggunakan Hive.
class BukuKomunikasiLocalStorage {
  static const String boxName = 'buku_komunikasi_cache_box';
  static const String keyData = 'buku_komunikasi_data';
  static const String keyTimestamp = 'buku_komunikasi_ts';
  static const String keyPendingNotes = 'buku_komunikasi_pending_notes';

  // Waktu kedaluwarsa cache (TTL): 1 Jam
  static const Duration cacheTtl = Duration(hours: 1);

  /// Inisialisasi Box Hive untuk Buku Komunikasi.
  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  /// Simpan data buku komunikasi ke Hive.
  Future<void> saveBukuKomunikasi(Map<String, dynamic> rawData) async {
    final box = await _getBox();
    await box.put(keyData, rawData);
    await box.put(keyTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  /// Baca data buku komunikasi dari Hive.
  /// Kembalikan null jika data kedaluwarsa atau tidak ada di cache.
  Future<Map<String, dynamic>?> loadBukuKomunikasi() async {
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

    final rawData = box.get(keyData);
    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }
    return null;
  }

  Future<void> savePendingNote({
    required int lineId,
    required String day,
    required String noteText,
    String? month,
    int? week,
  }) async {
    final box = await _getBox();
    final pending = box.get(keyPendingNotes) is List ? List<Map<String, dynamic>>.from(
      (box.get(keyPendingNotes) as List).map((item) => Map<String, dynamic>.from(item as Map)),
    ) : <Map<String, dynamic>>[];

    pending.add({
      'line_id': lineId,
      'day': day,
      'note_text': noteText,
      'month': month,
      'week': week,
      'saved_at': DateTime.now().toIso8601String(),
    });

    await box.put(keyPendingNotes, pending);
  }

  Future<List<Map<String, dynamic>>> loadPendingNotes() async {
    final box = await _getBox();
    final raw = box.get(keyPendingNotes);

    if (raw is! List) return <Map<String, dynamic>>[];

    return raw
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> clearPendingNotes() async {
    final box = await _getBox();
    await box.delete(keyPendingNotes);
  }

  /// Hapus seluruh cache data buku komunikasi.
  Future<void> clearCache() async {
    final box = await _getBox();
    await box.delete(keyData);
    await box.delete(keyTimestamp);
  }
}
