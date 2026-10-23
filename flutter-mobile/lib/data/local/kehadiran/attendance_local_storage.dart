import 'package:hive_flutter/hive_flutter.dart';

class AttendanceLocalStorage {
  static const String boxName = 'attendance_cache_box';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  String _key(String scope) {
    if (scope.trim().isEmpty) {
      throw ArgumentError.value(scope, 'scope', 'Tidak boleh kosong');
    }
    return 'attendance_snapshot_$scope';
  }

  Future<Map<String, dynamic>?> loadSnapshot({
    required String scope,
  }) async {
    final value = (await _getBox()).get(_key(scope));
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  Future<void> saveSnapshot({
    required String scope,
    required List<Map<String, dynamic>> items,
    required String cursor,
    required int fullSyncAt,
  }) async {
    await (await _getBox()).put(_key(scope), {
      'items': items,
      'cursor': cursor,
      'full_sync_at': fullSyncAt,
      'saved_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> clearCache({required String scope}) async {
    await (await _getBox()).delete(_key(scope));
  }
}
