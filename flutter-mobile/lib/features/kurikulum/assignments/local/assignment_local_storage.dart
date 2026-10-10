import 'package:hive_flutter/hive_flutter.dart';

class AssignmentLocalStorage {
  static const String _boxName = 'assignment_box';
  static const String _keyAssignmentsPrefix = 'cached_assignments';
  static const Duration fullSyncInterval = Duration(hours: 24);

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
    String? cursor,
    int? fullSyncAt,
  }) async {
    final box = await _getBox();
    final key = _assignmentsKey(cacheScope);
    final previous = box.get(key);
    await box.put(key, {
      'items': assignments,
      'cursor': cursor ?? (previous is Map ? previous['cursor'] : null),
      'full_sync_at':
          fullSyncAt ?? (previous is Map ? previous['full_sync_at'] : null),
      'saved_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<Map<String, dynamic>?> loadAssignmentSnapshot({
    required String cacheScope,
  }) async {
    final value = (await _getBox()).get(_assignmentsKey(cacheScope));
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  Future<List<Map<String, dynamic>>?> loadAssignments({
    required String cacheScope,
  }) async {
    final box = await _getBox();
    final value = box.get(_assignmentsKey(cacheScope));
    final data = value is Map ? value['items'] : value;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    }
    return null;
  }

  Future<void> clear({required String cacheScope}) async {
    try {
      final box = await _getBox();
      await box.delete(_assignmentsKey(cacheScope));
    } catch (_) {}
  }
}
