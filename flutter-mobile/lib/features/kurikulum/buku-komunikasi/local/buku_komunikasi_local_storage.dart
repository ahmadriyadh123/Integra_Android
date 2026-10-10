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
  String _key(String prefix, String scope) {
    if (scope.trim().isEmpty) {
      throw ArgumentError.value(scope, 'scope', 'Tidak boleh kosong');
    }
    return '${prefix}_$scope';
  }

  Future<void> saveBukuKomunikasi(
    Map<String, dynamic>? rawData, {
    required String scope,
  }) async {
    final box = await _getBox();
    await box.put(_key(keyData, scope), {
      'data': rawData,
      'saved_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Baca data buku komunikasi dari Hive.
  /// Kembalikan null jika data kedaluwarsa atau tidak ada di cache.
  Future<Map<String, dynamic>?> loadBukuKomunikasi({
    required String scope,
  }) async {
    final box = await _getBox();
    final snapshot = box.get(_key(keyData, scope));
    final rawData = snapshot is Map ? snapshot['data'] : null;
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
    required String scope,
  }) async {
    final box = await _getBox();
    final pendingKey = _key(keyPendingNotes, scope);
    final pending = box.get(pendingKey) is List ? List<Map<String, dynamic>>.from(
      (box.get(pendingKey) as List).map((item) => Map<String, dynamic>.from(item as Map)),
    ) : <Map<String, dynamic>>[];

    pending.add({
      'line_id': lineId,
      'day': day,
      'note_text': noteText,
      'month': month,
      'week': week,
      'saved_at': DateTime.now().toIso8601String(),
    });

    await box.put(pendingKey, pending);
  }

  Future<List<Map<String, dynamic>>> loadPendingNotes({required String scope}) async {
    final box = await _getBox();
    final raw = box.get(_key(keyPendingNotes, scope));

    if (raw is! List) return <Map<String, dynamic>>[];

    return raw
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> clearPendingNotes({required String scope}) async {
    final box = await _getBox();
    await box.delete(_key(keyPendingNotes, scope));
  }

  /// Hapus seluruh cache data buku komunikasi.
  Future<void> clearCache({required String scope}) async {
    final box = await _getBox();
    await box.delete(_key(keyData, scope));
  }
}
