import 'package:hive_flutter/hive_flutter.dart';

class AssignmentLocalStorage {
  static const String _boxName = 'assignment_box';
  static const String _keyAssignmentsPrefix = 'cached_assignments';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  String _assignmentsKey(String cacheScope) {
    if (cacheScope.trim().isEmpty) {
      throw ArgumentError.value(cacheScope, 'cacheScope', 'Tidak boleh kosong');
    }
    return '${_keyAssignmentsPrefix}_$cacheScope';
  }

  Future<void> saveAssignments(
    List<Map<String, dynamic>> assignments, {
    required String cacheScope,
  }) async {
    try {
      final box = await _getBox();
      await box.put(_assignmentsKey(cacheScope), assignments);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>?> loadAssignments({
    required String cacheScope,
  }) async {
    try {
      final box = await _getBox();
      final data = box.get(_assignmentsKey(cacheScope));
      if (data is List) {
        return data
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
      }
    } catch (_) {}
    return null;
  }

  Future<void> clear({required String cacheScope}) async {
    try {
      final box = await _getBox();
      await box.delete(_assignmentsKey(cacheScope));
    } catch (_) {}
  }
}
