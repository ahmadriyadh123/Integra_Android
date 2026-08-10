import 'package:hive_flutter/hive_flutter.dart';

/// Menyimpan dan membaca cache data elearning menggunakan Hive.
/// TTL default 1 jam — setelah itu data dianggap stale dan di-refresh dari API.
class ElearningLocalStorage {
  static const String boxName = 'elearning_cache_box';
  static const Duration _ttl = Duration(hours: 1);

  static const String _keyCourseList = 'elearning_course_list';
  static const String _keyCourseListTs = 'elearning_course_list_ts';
  static const String _keyCourseDetailPrefix = 'elearning_course_detail_';
  static const String _keyCourseDetailTsPrefix = 'elearning_course_detail_ts_';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  // ── Courses List ──────────────────────────────────────────────────────────

  /// Simpan daftar kursus ke cache.
  Future<void> saveCourses(List<Map<String, dynamic>> courses) async {
    final box = await _getBox();
    await box.put(_keyCourseList, courses);
    await box.put(_keyCourseListTs, DateTime.now().millisecondsSinceEpoch);
  }

  /// Baca daftar kursus dari cache. Kembalikan null jika tidak ada atau expired.
  Future<List<Map<String, dynamic>>?> loadCourses() async {
    final box = await _getBox();
    if (!_isFresh(box, _keyCourseListTs)) return null;

    final raw = box.get(_keyCourseList);
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return null;
  }

  // ── Course Detail ─────────────────────────────────────────────────────────

  /// Simpan detail kursus (beserta slides) ke cache.
  Future<void> saveCourseDetail(
      int courseId, Map<String, dynamic> detail) async {
    final box = await _getBox();
    await box.put('$_keyCourseDetailPrefix$courseId', detail);
    await box.put('$_keyCourseDetailTsPrefix$courseId',
        DateTime.now().millisecondsSinceEpoch);
  }

  /// Baca detail kursus dari cache. Kembalikan null jika tidak ada atau expired.
  Future<Map<String, dynamic>?> loadCourseDetail(int courseId) async {
    final box = await _getBox();
    if (!_isFresh(box, '$_keyCourseDetailTsPrefix$courseId')) return null;

    final raw = box.get('$_keyCourseDetailPrefix$courseId');
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  // ── Clear ─────────────────────────────────────────────────────────────────

  /// Hapus seluruh cache elearning.
  Future<void> clearAll() async {
    final box = await _getBox();
    final keys = box.keys
        .where((k) => k is String && k.startsWith('elearning_'))
        .toList();
    for (final key in keys) {
      await box.delete(key);
    }
  }

  /// Hapus cache detail untuk satu kursus.
  Future<void> clearCourseDetail(int courseId) async {
    final box = await _getBox();
    await box.delete('$_keyCourseDetailPrefix$courseId');
    await box.delete('$_keyCourseDetailTsPrefix$courseId');
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  bool _isFresh(Box box, String tsKey) {
    final ts = box.get(tsKey) as int?;
    if (ts == null) return false;
    final saved = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.now().difference(saved) < _ttl;
  }

  /// Kembalikan sisa waktu cache dalam menit (untuk ditampilkan di UI).
  Future<int?> courseListCacheAgeMinutes() async {
    final box = await _getBox();
    final ts = box.get(_keyCourseListTs) as int?;
    if (ts == null) return null;
    final saved = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.now().difference(saved).inMinutes;
  }
}
