import 'package:hive_flutter/hive_flutter.dart';

class AssignmentLocalStorage {
  static const String _boxName = 'assignment_box';
  static const String _keyAssignments = 'cached_assignments';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<void> saveAssignments(List<Map<String, dynamic>> assignments) async {
    try {
      final box = await _getBox();
      await box.put(_keyAssignments, assignments);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>?> loadAssignments() async {
    try {
      final box = await _getBox();
      final data = box.get(_keyAssignments);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return null;
  }

  Future<void> clear() async {
    try {
      final box = await _getBox();
      await box.delete(_keyAssignments);
    } catch (_) {}
  }
}
