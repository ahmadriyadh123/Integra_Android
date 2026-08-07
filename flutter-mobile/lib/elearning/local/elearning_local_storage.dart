import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan dan membaca cache data elearning dari SharedPreferences.
/// TTL default 1 jam — setelah itu data dianggap stale dan di-refresh dari API.
class ElearningLocalStorage {
  static const Duration _ttl = Duration(hours: 1);

  static const String _keyCourseList = 'elearning_course_list';
  static const String _keyCourseListTs = 'elearning_course_list_ts';
  static const String _keyCourseDetailPrefix = 'elearning_course_detail_';
  static const String _keyCourseDetailTsPrefix = 'elearning_course_detail_ts_';

  // ── Courses List ──────────────────────────────────────────────────────────

  /// Simpan daftar kursus ke cache.
  Future<void> saveCourses(List<Map<String, dynamic>> courses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCourseList, jsonEncode(courses));
    await prefs.setInt(
        _keyCourseListTs, DateTime.now().millisecondsSinceEpoch);
  }

  /// Baca daftar kursus dari cache. Kembalikan null jika tidak ada atau expired.
  Future<List<Map<String, dynamic>>?> loadCourses() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_isFresh(prefs, _keyCourseListTs)) return null;

    final raw = prefs.getString(_keyCourseList);
    if (raw == null) return null;

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  // ── Course Detail ─────────────────────────────────────────────────────────

  /// Simpan detail kursus (beserta slides) ke cache.
  Future<void> saveCourseDetail(
      int courseId, Map<String, dynamic> detail) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        '$_keyCourseDetailPrefix$courseId', jsonEncode(detail));
    await prefs.setInt('$_keyCourseDetailTsPrefix$courseId',
        DateTime.now().millisecondsSinceEpoch);
  }

  /// Baca detail kursus dari cache. Kembalikan null jika tidak ada atau expired.
  Future<Map<String, dynamic>?> loadCourseDetail(int courseId) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_isFresh(prefs, '$_keyCourseDetailTsPrefix$courseId')) return null;

    final raw = prefs.getString('$_keyCourseDetailPrefix$courseId');
    if (raw == null) return null;

    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Clear ─────────────────────────────────────────────────────────────────

  /// Hapus seluruh cache elearning.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((k) =>
            k.startsWith('elearning_'))
        .toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// Hapus cache detail untuk satu kursus.
  Future<void> clearCourseDetail(int courseId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyCourseDetailPrefix$courseId');
    await prefs.remove('$_keyCourseDetailTsPrefix$courseId');
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  bool _isFresh(SharedPreferences prefs, String tsKey) {
    final ts = prefs.getInt(tsKey);
    if (ts == null) return false;
    final saved = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.now().difference(saved) < _ttl;
  }

  /// Kembalikan sisa waktu cache dalam menit (untuk ditampilkan di UI).
  Future<int?> courseListCacheAgeMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_keyCourseListTs);
    if (ts == null) return null;
    final saved = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.now().difference(saved).inMinutes;
  }
}
