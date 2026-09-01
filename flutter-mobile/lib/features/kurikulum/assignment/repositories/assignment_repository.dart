import '../local/assignment_local_storage.dart';
import '../models/assignment_model.dart';
import '../services/assignment_service.dart';

class AssignmentRepository {
  final AssignmentService apiService;
  final AssignmentLocalStorage localStorage;

  AssignmentRepository({
    required this.apiService,
    required this.localStorage,
  });

  Future<List<AssignmentItem>> getAssignments(String token, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await localStorage.loadAssignments();
      if (cached != null && cached.isNotEmpty) {
        return cached.map((e) => AssignmentItem.fromJson(e)).toList();
      }
    }

    final rawData = await apiService.fetchAssignments(token);
    await localStorage.saveAssignments(rawData);
    return rawData.map((e) => AssignmentItem.fromJson(e)).toList();
  }

  Future<List<Map<String, dynamic>>?> loadCachedAssignments() {
    return localStorage.loadAssignments();
  }

  Future<void> saveCachedAssignments(List<Map<String, dynamic>> data) {
    return localStorage.saveAssignments(data);
  }

  Future<void> clearCache() {
    return localStorage.clear();
  }
}
