import '../models/elearning_model.dart';
import '../services/elearning_service.dart';

class ElearningRepository {
  final ElearningService apiService;

  ElearningRepository({required this.apiService});

  Future<List<CourseItem>> getCourses(String token) async {
    final data = await apiService.fetchCourses(token);
    return data
        .map((e) => CourseItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CourseDetail> getCourseDetail(String token, int courseId) async {
    final data = await apiService.fetchCourseDetail(token, courseId);
    return CourseDetail.fromJson(data);
  }
}
