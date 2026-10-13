import 'package:hive_flutter/hive_flutter.dart';
import 'dart:typed_data';

/// Service untuk menyimpan dan membaca cache data Weekly Plan menggunakan Hive.
class WeeklyPlanLocalStorage {
  static const String boxName = 'weekly_plan_cache_box';
  static const String keyList = 'weekly_plan_list';
  static const String keyTimestamp = 'weekly_plan_list_ts';
  
  // Waktu kedaluwarsa cache (TTL): 1 Jam
  static const Duration cacheTtl = Duration(hours: 1);

  /// Inisialisasi Box Hive untuk Weekly Plan.
  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  /// Simpan daftar weekly plan ke Hive.
  String _snapshotKey(String scope) {
    if (scope.trim().isEmpty) {
      throw ArgumentError.value(scope, 'scope', 'Tidak boleh kosong');
    }
    return '${keyList}_$scope';
  }

  String _pdfKey(int planId, String scope) {
    if (scope.trim().isEmpty) {
      throw ArgumentError.value(scope, 'scope', 'Tidak boleh kosong');
    }
    return 'weekly_plan_pdf_${scope}_$planId';
  }

  Future<void> saveWeeklyPlanPdf(
    int planId,
    Uint8List pdfBytes, {
    required String scope,
  }) async {
    await (await _getBox()).put(_pdfKey(planId, scope), pdfBytes);
  }

  Future<Uint8List?> loadWeeklyPlanPdf(
    int planId, {
    required String scope,
  }) async {
    final value = (await _getBox()).get(_pdfKey(planId, scope));
    if (value is Uint8List) return value;
    if (value is List<int>) return Uint8List.fromList(value);
    return null;
  }

  Future<void> saveWeeklyPlanList(
    List<dynamic> plans, {
    required String scope,
    required String cursor,
    required int fullSyncAt,
  }) async {
    final box = await _getBox();
    await box.put(_snapshotKey(scope), {
      'items': plans,
      'cursor': cursor,
      'full_sync_at': fullSyncAt,
      'saved_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<Map<String, dynamic>?> loadWeeklyPlanSnapshot({
    required String scope,
  }) async {
    final value = (await _getBox()).get(_snapshotKey(scope));
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  /// Baca daftar weekly plan dari Hive.
  /// Kembalikan null jika data kedaluwarsa atau tidak ada di cache.
  Future<List<dynamic>?> loadWeeklyPlanList({required String scope}) async {
    final box = await _getBox();
    final snapshot = box.get(_snapshotKey(scope));
    final plans = snapshot is Map ? snapshot['items'] : null;
    if (plans is List) {
      return plans;
    }
    return null;
  }

  /// Hapus seluruh cache data weekly plan.
  Future<void> clearCache({required String scope}) async {
    final box = await _getBox();
    await box.delete(_snapshotKey(scope));
  }
}
