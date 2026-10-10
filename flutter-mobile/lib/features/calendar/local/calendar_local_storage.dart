import 'package:hive_flutter/hive_flutter.dart';

class CalendarLocalStorage {
  static const String boxName = 'calendar_cache_box';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) return Hive.openBox(boxName);
    return Hive.box(boxName);
  }

  String _key(String scope) {
    if (scope.trim().isEmpty) {
      throw ArgumentError.value(scope, 'scope', 'Tidak boleh kosong');
    }
    return 'calendar_snapshot_$scope';
  }

  Future<Map<String, dynamic>?> loadSnapshot({
    required String cacheScope,
  }) async {
    final value = (await _getBox()).get(_key(cacheScope));
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  Future<void> saveSnapshot({
    required String cacheScope,
    required List<Map<String, dynamic>> items,
    required String cursor,
    required int fullSyncAt,
  }) async {
    await (await _getBox()).put(_key(cacheScope), {
      'items': items,
      'cursor': cursor,
      'full_sync_at': fullSyncAt,
      'saved_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> clearCache({required String cacheScope}) async {
    await (await _getBox()).delete(_key(cacheScope));
  }
}
