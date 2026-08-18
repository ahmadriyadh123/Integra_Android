import '../local/weekly_plan_local_storage.dart';
import '../models/weekly_plan_model.dart';
import '../services/weekly_plan_service.dart';

class WeeklyPlanRepository {
  final WeeklyPlanService apiService;
  final WeeklyPlanLocalStorage localStorage;

  WeeklyPlanRepository({
    required this.apiService,
    required this.localStorage,
  });

  Future<List<WeeklyPlanItem>> getWeeklyPlanList(String token,
      {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await localStorage.loadWeeklyPlanList();
      if (cached != null) {
        return cached
            .map((e) => WeeklyPlanItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    final data = await apiService.fetchWeeklyPlanList(token);
    final plans = data
        .map((e) => WeeklyPlanItem.fromJson(e as Map<String, dynamic>))
        .toList();

    await localStorage.saveWeeklyPlanList(data);

    return plans;
  }

  /// Kembalikan URL PDF yang bisa langsung dibuka oleh SfPdfViewer.network
  String getPdfUrl(int planId) {
    return apiService.getPdfUrl(apiService.baseUrl, planId);
  }
}
