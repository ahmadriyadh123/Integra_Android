import '../models/weekly_plan_model.dart';
import '../services/weekly_plan_service.dart';

class WeeklyPlanRepository {
  final WeeklyPlanService apiService;

  WeeklyPlanRepository({required this.apiService});

  Future<List<WeeklyPlanItem>> getWeeklyPlanList(String token) async {
    final data = await apiService.fetchWeeklyPlanList(token);
    return data
        .map((e) => WeeklyPlanItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Kembalikan URL PDF yang bisa langsung dibuka oleh SfPdfViewer.network
  String getPdfUrl(int planId) {
    return apiService.getPdfUrl(apiService.baseUrl, planId);
  }
}
