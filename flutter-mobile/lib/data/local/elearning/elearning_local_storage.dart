import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Menyimpan dan membaca cache data elearning menggunakan Hive.
/// TTL default 1 jam — setelah itu data dianggap stale dan di-refresh dari API.
class ElearningLocalStorage {
  static const String boxName = 'elearning_cache_box';
  static const Duration _ttl = Duration(hours: 1);

  final Future<Directory> Function() _supportDirectoryProvider;

  ElearningLocalStorage({
    Future<Directory> Function()? supportDirectoryProvider,
  }) : _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory;

  static const String _keyPrefix = 'elearning_';
  static const String _keyCourseList = 'courses';
  static const String _keyCourseListTs = 'courses_ts';
  static const String _keyCoursesSyncCursor = 'courses_sync_cursor';
  static const String _keyCoursesFullSyncTs = 'courses_full_sync_ts';
  static const String _keyCourseDetailPrefix = 'course_detail_';
  static const String _keyCourseDetailTsPrefix = 'course_detail_ts_';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }


  /// Simpan daftar kursus ke cache.
  Future<void> saveCourses(
    List<Map<String, dynamic>> courses, {
    required String cacheScope,
  }) async {
    final box = await _getBox();
    await box.put(_key(cacheScope, _keyCourseList), courses);
    await box.put(
      _key(cacheScope, _keyCourseListTs),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Baca daftar kursus dari cache. Kembalikan null jika tidak ada atau expired.
  Future<List<Map<String, dynamic>>?> loadCourses({
    required String cacheScope,
  }) async {
    final box = await _getBox();
    if (!_isFresh(box, _key(cacheScope, _keyCourseListTs))) return null;

    return _readCourses(box, _key(cacheScope, _keyCourseList));
  }

  /// Baca cache meskipun TTL terlewati agar delta dapat digabung dengan data lama.
  Future<List<Map<String, dynamic>>?> loadStoredCourses({
    required String cacheScope,
  }) async {
    final box = await _getBox();
    return _readCourses(box, _key(cacheScope, _keyCourseList));
  }

  List<Map<String, dynamic>>? _readCourses(Box box, String key) {
    final raw = box.get(key);
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return null;
  }

  Future<String?> loadCoursesSyncCursor({
    required String cacheScope,
  }) async {
    final box = await _getBox();
    return box.get(_key(cacheScope, _keyCoursesSyncCursor)) as String?;
  }

  Future<void> saveCoursesSyncCursor(
    String cursor, {
    required String cacheScope,
  }) async {
    final box = await _getBox();
    await box.put(_key(cacheScope, _keyCoursesSyncCursor), cursor);
  }

  Future<bool> isCoursesFullSyncDue({
    required String cacheScope,
  }) async {
    final box = await _getBox();
    final timestamp = box.get(_key(cacheScope, _keyCoursesFullSyncTs)) as int?;
    if (timestamp == null) return true;
    final saved = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(saved) >= const Duration(hours: 24);
  }

  Future<void> saveCoursesFullSyncTimestamp({
    required String cacheScope,
  }) async {
    final box = await _getBox();
    await box.put(
      _key(cacheScope, _keyCoursesFullSyncTs),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Simpan detail kursus (beserta slides) ke cache.
  Future<void> saveCourseDetail(
    int courseId,
    Map<String, dynamic> detail, {
    required String cacheScope,
  }) async {
    final box = await _getBox();
    await box.put(
      _key(cacheScope, '$_keyCourseDetailPrefix$courseId'),
      detail,
    );
    await box.put(
      _key(cacheScope, '$_keyCourseDetailTsPrefix$courseId'),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Baca detail kursus dari cache. Kembalikan null jika tidak ada atau expired.
  Future<Map<String, dynamic>?> loadCourseDetail(
    int courseId, {
    required String cacheScope,
  }) async {
    final box = await _getBox();
    final timestampKey =
        _key(cacheScope, '$_keyCourseDetailTsPrefix$courseId');
    if (!_isFresh(box, timestampKey)) return null;

    final raw = box.get(_key(cacheScope, '$_keyCourseDetailPrefix$courseId'));
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  /// Read a possibly stale detail snapshot so it can be shown during refresh.
  Future<Map<String, dynamic>?> loadStoredCourseDetail(
    int courseId, {
    required String cacheScope,
  }) async {
    final box = await _getBox();
    final raw = box.get(_key(cacheScope, '$_keyCourseDetailPrefix$courseId'));
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  /// Hapus cache E-Learning hanya untuk tenant dan pengguna yang aktif.
  Future<void> clearAll({required String cacheScope}) async {
    final box = await _getBox();
    final keys = box.keys
        .where(
          (key) =>
              key is String &&
              key.startsWith(_scopePrefix(cacheScope)),
        )
        .toList();
    for (final key in keys) {
      await box.delete(key);
    }
    final offlineDirectory = await _offlineDirectory(cacheScope);
    if (await offlineDirectory.exists()) {
      await offlineDirectory.delete(recursive: true);
    }
  }

  /// Hapus cache detail untuk satu kursus.
  Future<void> clearCourseDetail(
    int courseId, {
    required String cacheScope,
  }) async {
    final box = await _getBox();
    await box.delete(_key(cacheScope, '$_keyCourseDetailPrefix$courseId'));
    await box.delete(
      _key(cacheScope, '$_keyCourseDetailTsPrefix$courseId'),
    );
  }

  Future<File?> loadOfflineMaterial(
    int slideId, {
    required String cacheScope,
  }) async {
    final box = await _getBox();
    final key = _key(cacheScope, 'offline_material_$slideId');
    final storedPath = box.get(key);
    if (storedPath is! String || storedPath.isEmpty) return null;

    final file = File(storedPath);
    if (await file.exists()) return file;
    await box.delete(key);
    return null;
  }

  Future<File> saveOfflineMaterial(
    int slideId, {
    required String cacheScope,
    required String fileName,
    required Stream<List<int>> content,
  }) async {
    final directory = await _offlineDirectory(cacheScope);
    await directory.create(recursive: true);
    final safeName = _safeFileName(fileName);
    final target = File('${directory.path}${Platform.pathSeparator}$safeName');
    final temporary = File(
      '${target.path}.${DateTime.now().microsecondsSinceEpoch}.part',
    );

    try {
      final sink = temporary.openWrite();
      await content.pipe(sink);
      if (await temporary.length() == 0) {
        throw const FormatException('Berkas materi yang diunduh kosong.');
      }

      if (await target.exists()) await target.delete();
      final savedFile = await temporary.rename(target.path);
      final box = await _getBox();
      await box.put(
        _key(cacheScope, 'offline_material_$slideId'),
        savedFile.path,
      );
      return savedFile;
    } catch (_) {
      if (await temporary.exists()) await temporary.delete();
      rethrow;
    }
  }

  Future<void> removeOfflineMaterial(
    int slideId, {
    required String cacheScope,
  }) async {
    final box = await _getBox();
    final key = _key(cacheScope, 'offline_material_$slideId');
    final storedPath = box.get(key);
    if (storedPath is String && storedPath.isNotEmpty) {
      final file = File(storedPath);
      if (await file.exists()) await file.delete();
    }
    await box.delete(key);
  }

  Future<Directory> _offlineDirectory(String cacheScope) async {
    final directory = await _supportDirectoryProvider();
    return Directory(
      '${directory.path}${Platform.pathSeparator}elearning_offline'
      '${Platform.pathSeparator}${_safeFileName(cacheScope)}',
    );
  }

  String _safeFileName(String value) {
    final safe = value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return safe.isEmpty ? 'material' : safe;
  }

  bool _isFresh(Box box, String tsKey) {
    final ts = box.get(tsKey) as int?;
    if (ts == null) return false;
    final saved = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.now().difference(saved) < _ttl;
  }

  /// Kembalikan sisa waktu cache dalam menit (untuk ditampilkan di UI).
  Future<int?> courseListCacheAgeMinutes({
    required String cacheScope,
  }) async {
    final box = await _getBox();
    final ts = box.get(_key(cacheScope, _keyCourseListTs)) as int?;
    if (ts == null) return null;
    final saved = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.now().difference(saved).inMinutes;
  }

  String _key(String cacheScope, String key) =>
      '${_scopePrefix(cacheScope)}$key';

  String _scopePrefix(String cacheScope) {
    if (cacheScope.trim().isEmpty) {
      throw ArgumentError.value(cacheScope, 'cacheScope', 'Tidak boleh kosong');
    }
    return '$_keyPrefix${cacheScope}_';
  }
}
