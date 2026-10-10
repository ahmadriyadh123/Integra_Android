import 'dart:convert';

import '../local/elearning_local_storage.dart';
import '../models/elearning_model.dart';
import '../services/elearning_service.dart';

class ElearningRepository {
  final ElearningService apiService;
  final ElearningLocalStorage localStorage;

  ElearningRepository({
    required this.apiService,
    required this.localStorage,
  });

  Future<List<CourseItem>> getCourses(String token, {bool forceRefresh = false}) async {
    final cacheScope = cacheScopeForToken(token);
    final cached = await localStorage.loadStoredCourses(cacheScope: cacheScope);
    final cursor = await localStorage.loadCoursesSyncCursor(
      cacheScope: cacheScope,
    );
    final fullSync = cached == null ||
        cursor == null ||
        await localStorage.isCoursesFullSyncDue(cacheScope: cacheScope);
    final result = await apiService.syncCourses(
      token,
      cursor: fullSync ? null : cursor,
    );

    final rawItems = result['items'];
    final rawRemovedIds = result['removed_ids'];
    final nextCursor = result['next_cursor'];
    final rawFullSync = result['full_sync'];
    if (rawItems is! List ||
        rawRemovedIds is! List ||
        nextCursor is! String ||
        nextCursor.isEmpty ||
        rawFullSync is! bool ||
        (fullSync && !rawFullSync)) {
      throw const FormatException('Respons sinkronisasi kursus tidak lengkap');
    }
    final isFullSync = rawFullSync;

    final remoteCourses = rawItems
        .map(
          (item) => CourseItem.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
    final removedIds = rawRemovedIds.map((value) {
      if (value is int) return value;
      final parsed = int.tryParse(value.toString());
      if (parsed == null) {
        throw const FormatException('ID kursus yang dihapus tidak valid');
      }
      return parsed;
    }).toList();

    final merged = <int, CourseItem>{};
    if (!isFullSync && cached != null) {
      for (final item in cached) {
        final course = CourseItem.fromJson(item);
        merged[course.id] = course;
      }
      for (final courseId in removedIds) {
        merged.remove(courseId);
      }
    }
    for (final course in remoteCourses) {
      merged[course.id] = course;
    }

    final courses = merged.values.toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    await localStorage.saveCourses(
      courses.map(_courseItemToMap).toList(),
      cacheScope: cacheScope,
    );
    await localStorage.saveCoursesSyncCursor(
      nextCursor,
      cacheScope: cacheScope,
    );
    if (isFullSync) {
      await localStorage.saveCoursesFullSyncTimestamp(
        cacheScope: cacheScope,
      );
    }
    return courses;
  }

  Future<CourseDetail> getCourseDetail(String token, int courseId,
      {bool forceRefresh = false}) async {
    final cacheScope = cacheScopeForToken(token);
    final data = await apiService.fetchCourseDetail(token, courseId);
    final detail = CourseDetail.fromJson(data);

    await localStorage.saveCourseDetail(
      courseId,
      _courseDetailToMap(detail),
      cacheScope: cacheScope,
    );

    return detail;
  }

  Future<String> getSlideContent(String token, int slideId) {
    return apiService.fetchSlideContent(token, slideId);
  }

  Future<void> markSlideCompleted(
    String token,
    int courseId,
    int slideId, {
    required String source,
    String? completionStatus,
  }) {
    return apiService.markSlideCompleted(
      token,
      courseId,
      slideId,
      source: source,
      completionStatus: completionStatus,
    );
  }

  Future<List<CourseMessage>> getCourseMessages(
    String token,
    int courseId,
  ) async {
    final data = await apiService.fetchCourseMessages(token, courseId);
    return data
        .map(
          (item) => CourseMessage.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> sendCourseMessage(
    String token,
    int courseId,
    String body,
  ) {
    return apiService.sendCourseMessage(token, courseId, body);
  }

  Future<List<Map<String, dynamic>>?> loadCachedCourses(String token) {
    return localStorage.loadCourses(
      cacheScope: cacheScopeForToken(token),
    );
  }

  Future<void> saveCachedCourses(String token, List<CourseItem> courses) {
    return localStorage.saveCourses(
      courses.map(_courseItemToMap).toList(),
      cacheScope: cacheScopeForToken(token),
    );
  }

  Future<Map<String, dynamic>?> loadCachedCourseDetail(
    String token,
    int courseId,
  ) {
    return localStorage.loadStoredCourseDetail(
      courseId,
      cacheScope: cacheScopeForToken(token),
    );
  }

  Future<void> saveCachedCourseDetail(
    String token,
    int courseId,
    CourseDetail detail,
  ) {
    return localStorage.saveCourseDetail(
      courseId,
      _courseDetailToMap(detail),
      cacheScope: cacheScopeForToken(token),
    );
  }

  Future<void> clearAllCache(String token) {
    return localStorage.clearAll(cacheScope: cacheScopeForToken(token));
  }

  Future<void> clearCourseDetailCache(String token, int courseId) {
    return localStorage.clearCourseDetail(
      courseId,
      cacheScope: cacheScopeForToken(token),
    );
  }

  String cacheScopeForToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException(
        'Token login tidak valid untuk cache E-Learning.',
      );
    }

    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map<String, dynamic>) {
        throw const FormatException();
      }

      final schoolId = _parseId(payload['school_id']);
      final userId = _parseId(payload['uid']);
      if (schoolId == null || userId == null) {
        throw const FormatException();
      }
      return 'school_${schoolId}_user_$userId';
    } on FormatException {
      throw const FormatException(
        'Token login tidak memiliki identitas sekolah dan pengguna yang valid.',
      );
    }
  }

  int? _parseId(dynamic value) {
    if (value is int && value > 0) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  Map<String, dynamic> _courseItemToMap(CourseItem c) => {
        'id': c.id,
        'title': c.title,
        'teacher_name': c.teacherName,
        'total_slides': c.totalSlides,
        'completed_slides': c.completedSlides,
        'progress_percent': c.progressPercent,
        'description': c.description,
      };

  Map<String, dynamic> _courseDetailToMap(CourseDetail d) => {
        'id': d.id,
        'title': d.title,
        'teacher_name': d.teacherName,
        'description': d.description,
        'total_slides': d.totalSlides,
        'completed_slides': d.completedSlides,
        'progress_percent': d.progressPercent,
        'slides': d.slides
            .map((s) => {
                  'id': s.id,
                  'title': s.title,
                  'material_type': s.materialType,
                  'download_url': s.downloadUrl,
                  'sequence': s.sequence,
                  'is_completed': s.isCompleted,
                })
            .toList(),
      };
}
