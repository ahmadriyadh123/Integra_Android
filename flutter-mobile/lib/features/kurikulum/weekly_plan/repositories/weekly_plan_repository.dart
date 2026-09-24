import 'dart:typed_data';
import '../local/weekly_plan_local_storage.dart';
import '../models/weekly_plan_model.dart';
import '../models/weekly_plan_detail_model.dart';
import '../services/weekly_plan_service.dart';

class WeeklyPlanRepository {
  final WeeklyPlanService apiService;
  final WeeklyPlanLocalStorage localStorage;

  WeeklyPlanRepository({
    required this.apiService,
    required this.localStorage,
  });

  Future<List<WeeklyPlanItem>> getWeeklyPlanList(String token, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await localStorage.loadWeeklyPlanList();
      if (cached != null) {
        return cached.whereType<Map>().map((e) => WeeklyPlanItem.fromJson(e)).toList();
      }
    }
    final data = await apiService.fetchWeeklyPlanList(token);
    final plans = data.whereType<Map>().map((e) => WeeklyPlanItem.fromJson(e)).toList();
    await localStorage.saveWeeklyPlanList(data);
    return plans;
  }

  /// Ambil detail dokumen dan mapping ke model
  Future<WeeklyPlanDetailModel> getWeeklyPlanDetail(int planId, String token) async {
    final data = await apiService.fetchWeeklyPlanDetail(planId, token);
    return WeeklyPlanDetailModel.fromJson(data);
  }

  /// Mengambil binary bytes PDF via Service
  Future<Uint8List> getWeeklyPlanPdfFile(int planId, String token) async {
    return await apiService.fetchWeeklyPlanPdfFile(planId, token);
  }
}