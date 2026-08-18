import '../local/rapor_local_storage.dart';
import '../models/rapor_model.dart';
import '../services/rapor_service.dart';

class RaporRepository {
  final RaporService apiService;
  final RaporLocalStorage localStorage;

  RaporRepository({
    required this.apiService,
    required this.localStorage,
  });

  Future<List<ReportCardHeader>> getReportList(String token,
      {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await localStorage.loadRaporList();
      if (cached != null) {
        return cached
            .map((e) => ReportCardHeader.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    final data = await apiService.fetchReportList(token);
    final reports = data
        .map((e) => ReportCardHeader.fromJson(e as Map<String, dynamic>))
        .toList();

    await localStorage.saveRaporList(data);

    return reports;
  }

  Future<ReportCardDetail> getReportDetail(String token, int raporId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await localStorage.loadRaporDetail(raporId);
      if (cached != null) {
        return ReportCardDetail.fromJson(cached);
      }
    }

    final data = await apiService.fetchReportDetail(token, raporId);
    final detail = ReportCardDetail.fromJson(data);

    await localStorage.saveRaporDetail(raporId, data);

    return detail;
  }
}
