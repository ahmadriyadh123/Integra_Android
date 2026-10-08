import 'package:hive_flutter/hive_flutter.dart';

class ProfileLocalStorage {
  static const String _boxName = 'profile_cache_box';

  Future<Box> _box() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<Map<String, dynamic>?> loadProfile(String cacheKey) async {
    final box = await _box();
    final value = box.get(cacheKey);
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  Future<void> saveProfile(
    String cacheKey,
    Map<String, dynamic> profile,
  ) async {
    final box = await _box();
    await box.put(cacheKey, profile);
  }
}
