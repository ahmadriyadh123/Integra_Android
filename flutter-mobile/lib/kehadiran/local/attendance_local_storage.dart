import 'package:hive_flutter/hive_flutter.dart';

/// Service untuk menyimpan dan membaca cache data Kehadiran (Attendance) menggunakan Hive.
/// Ini bertindak sebagai local cache layer sebelum mengambil data terbaru dari API.
class AttendanceLocalStorage {
  static const String boxName = 'attendance_cache_box';
  static const String keyHistory = 'attendance_history_list';
  static const String keyTimestamp = 'attendance_history_ts';
  
  // Waktu kedaluwarsa cache (TTL): 1 Jam
  static const Duration cacheTtl = Duration(hours: 1);

  /// Inisialisasi Box Hive untuk Kehadiran.
  /// Harus dipanggil setelah Hive.initFlutter() di main.dart.
  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  /// Simpan list data kehadiran mentah (List of Maps) ke Hive.
  Future<void> saveAttendanceHistory(List<dynamic> rawData) async {
    final box = await _getBox();
    await box.put(keyHistory, rawData);
    await box.put(keyTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  /// Baca list data kehadiran dari Hive.
  /// Kembalikan null jika data kedaluwarsa (lebih dari 1 jam) atau tidak ada di cache.
  Future<List<dynamic>?> loadAttendanceHistory() async {
    final box = await _getBox();
    
    // Cek kesegaran cache (Timestamp)
    final ts = box.get(keyTimestamp) as int?;
    if (ts == null) return null;

    final savedTime = DateTime.fromMillisecondsSinceEpoch(ts);
    final isExpired = DateTime.now().difference(savedTime) > cacheTtl;
    
    if (isExpired) {
      // Hapus data cache jika sudah kadaluwarsa
      await clearCache();
      return null;
    }

    final rawData = box.get(keyHistory);
    if (rawData is List) {
      return rawData;
    }
    return null;
  }

  /// Hapus seluruh cache data kehadiran.
  Future<void> clearCache() async {
    final box = await _getBox();
    await box.delete(keyHistory);
    await box.delete(keyTimestamp);
  }
}
