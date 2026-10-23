import 'package:hive_flutter/hive_flutter.dart';

/// Service untuk menyimpan dan membaca cache data Buku Komunikasi menggunakan Hive.
class BukuKomunikasiLocalStorage {
  static const String boxName = 'buku_komunikasi_cache_box';
  static const String keyData = 'buku_komunikasi_data';
  static const String keyTimestamp = 'buku_komunikasi_ts';
  static const String keyPendingNotes = 'buku_komunikasi_pending_notes';
  static const String _keyCursor = 'buku_komunikasi_cursor';

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

  Future<bool> isBukuKomunikasiFresh({required String scope}) async {
    final box = await _getBox();
    final snapshot = box.get(_key(keyData, scope));
    if (snapshot is! Map || snapshot['saved_at'] is! int) return false;
    final savedAt = snapshot['saved_at'] as int;
    return DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(savedAt),
        ) <
        cacheTtl;
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

  /// Hapus satu item dari pending queue berdasarkan index.
  /// Digunakan oleh sync agar catatan yang berhasil dikirim langsung dihapus
  /// tanpa mempengaruhi item lain yang mungkin belum terkirim.
  Future<void> removePendingNoteAt(int index, {required String scope}) async {
    final box = await _getBox();
    final pendingKey = _key(keyPendingNotes, scope);
    final pending = box.get(pendingKey);
    if (pending is! List || index < 0 || index >= pending.length) return;
    final updated = List<Map<String, dynamic>>.from(
      pending.map((item) => Map<String, dynamic>.from(item as Map)),
    )..removeAt(index);
    if (updated.isEmpty) {
      await box.delete(pendingKey);
    } else {
      await box.put(pendingKey, updated);
    }
  }

  /// Hapus seluruh cache data buku komunikasi (data + cursor + full sync ts).
  Future<void> clearCache({required String scope}) async {
    final box = await _getBox();
    await box.delete(_key(keyData, scope));
    await box.delete(_key(_keyCursor, scope));
    await box.delete(_key(_keyFullSyncAt, scope));
  }

  // ── Cursor untuk delta sync ──────────────────────────────────────────────

  static const String _keyFullSyncAt = 'buku_komunikasi_full_sync_at';

  /// Interval full sync: setiap 24 jam backend ditarik penuh untuk menangkap
  /// data yang hilang dari delta (mis. perubahan tanpa update write_date).
  static const Duration fullSyncInterval = Duration(hours: 24);

  Future<String?> loadCursor({required String scope}) async {
    final box = await _getBox();
    final value = box.get(_key(_keyCursor, scope));
    return value is String ? value : null;
  }

  Future<void> saveCursor(String cursor, {required String scope}) async {
    final box = await _getBox();
    await box.put(_key(_keyCursor, scope), cursor);
  }

  /// Timestamp (ms) sinkronisasi penuh terakhir. Dipakai untuk memutuskan
  /// kapan harus melakukan full sync lagi, alih-alih delta sync.
  Future<int?> loadFullSyncAt({required String scope}) async {
    final box = await _getBox();
    final value = box.get(_key(_keyFullSyncAt, scope));
    return value is int ? value : null;
  }

  Future<void> saveFullSyncAt(int timestamp, {required String scope}) async {
    final box = await _getBox();
    await box.put(_key(_keyFullSyncAt, scope), timestamp);
  }
}
