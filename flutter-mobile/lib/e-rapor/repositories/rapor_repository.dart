import '../models/rapor_model.dart';
import '../services/rapor_service.dart';

class RaporRepository {
  final RaporService apiService;

  RaporRepository({required this.apiService});

  Future<List<ReportCardHeader>> getReportList(String token) async {
    final data = await apiService.fetchReportList(token);
    return data
        .map((e) => ReportCardHeader.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReportCardDetail> getReportDetail(String token, int raporId) async {
    final data = await apiService.fetchReportDetail(token, raporId);
    return ReportCardDetail.fromJson(data);
  }
}
