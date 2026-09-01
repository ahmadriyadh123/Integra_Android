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
    if (!forceRefresh) {
      final cached = await localStorage.loadCourses();
      if (cached != null && cached.isNotEmpty) {
        return cached.map((item) => CourseItem.fromJson(item)).toList();
      }
    }

    final data = await apiService.fetchCourses(token);
    final courses = data
        .map((e) => CourseItem.fromJson(e as Map<String, dynamic>))
        .toList();

    await localStorage.saveCourses(
      courses.map(_courseItemToMap).toList(),
    );

    return courses;
  }

  Future<CourseDetail> getCourseDetail(String token, int courseId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await localStorage.loadCourseDetail(courseId);
      if (cached != null) {
        return CourseDetail.fromJson(cached);
      }
    }

    final data = await apiService.fetchCourseDetail(token, courseId);
    final detail = CourseDetail.fromJson(data);

    await localStorage.saveCourseDetail(
      courseId,
      _courseDetailToMap(detail),
    );

    return detail;
  }

  Future<String> getSlideContent(String token, int slideId) {
    return apiService.fetchSlideContent(token, slideId);
  }

  Future<List<Map<String, dynamic>>?> loadCachedCourses() {
    return localStorage.loadCourses();
  }

  Future<void> saveCachedCourses(List<CourseItem> courses) {
    return localStorage.saveCourses(courses.map(_courseItemToMap).toList());
  }

  Future<Map<String, dynamic>?> loadCachedCourseDetail(int courseId) {
    return localStorage.loadCourseDetail(courseId);
  }

  Future<void> saveCachedCourseDetail(int courseId, CourseDetail detail) {
    return localStorage.saveCourseDetail(courseId, _courseDetailToMap(detail));
  }

  Future<void> clearAllCache() {
    return localStorage.clearAll();
  }

  Future<void> clearCourseDetailCache(int courseId) {
    return localStorage.clearCourseDetail(courseId);
  }

  Map<String, dynamic> _courseItemToMap(CourseItem c) => {
        'id': c.id,
        'title': c.title,
        'teacher_name': c.teacherName,
        'total_slides': c.totalSlides,
        'description': c.description,
      };

  Map<String, dynamic> _courseDetailToMap(CourseDetail d) => {
        'id': d.id,
        'title': d.title,
        'teacher_name': d.teacherName,
        'description': d.description,
        'total_slides': d.totalSlides,
        'slides': d.slides
            .map((s) => {
                  'id': s.id,
                  'title': s.title,
                  'material_type': s.materialType,
                  'download_url': s.downloadUrl,
                  'sequence': s.sequence,
                })
            .toList(),
      };
}
