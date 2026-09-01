import 'dart:typed_data';
import '../local/rapor_local_storage.dart';
import '../models/rapor_model.dart';
import '../services/rapor_service.dart';
import '../services/rapor_pdf_generator_service.dart';
import '../../auth/models/auth_model.dart';

class RaporRepository {
  final RaporService apiService;
  final RaporLocalStorage localStorage;

  RaporRepository({
    required this.apiService,
    required this.localStorage,
  });

  /// Kembalikan URL endpoint PDF — langsung di-stream oleh middleware
  String getPdfUrl(int raporId) {
    return '${apiService.baseUrl}/e-rapor/pdf/$raporId';
  }

  Future<Uint8List> generatePdf(
    ReportCardDetail detail,
    ReportCardHeader? header,
    UserProfile? user,
  ) {
    return RaporPdfGeneratorService.generateRaporPdf(detail, header, user);
  }

  Future<List<ReportCardHeader>> getReportList(String token,
      {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await localStorage.loadRaporList();
      if (cached != null) {
        return cached
            .map((e) => ReportCardHeader.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    }

    final data = await apiService.fetchReportList(token);
    final reports = data
        .map((e) => ReportCardHeader.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();

    await localStorage.saveRaporList(data);

    return reports;
  }

  Future<ReportCardDetail> getReportDetail(String token, int raporId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await localStorage.loadRaporDetail(raporId);
      if (cached != null) {
        return ReportCardDetail.fromJson(
            Map<String, dynamic>.from(cached));
      }
    }

    final data = await apiService.fetchReportDetail(token, raporId);
    final detail = ReportCardDetail.fromJson(data);

    await localStorage.saveRaporDetail(raporId, data);

    return detail;
  }
}
