import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/user_friendly_error.dart';
import '../models/rapor_model.dart';
import '../repositories/rapor_repository.dart';
import '../../auth/models/auth_model.dart';

class RaporViewModel extends ChangeNotifier {
  final RaporRepository repository;

  RaporViewModel({required this.repository});
  String? get lastSyncError => repository.lastSyncError == null
      ? null
      : userFriendlyError(repository.lastSyncError!);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage =>
      _errorMessage == null ? null : userFriendlyError(_errorMessage!);

  List<ReportCardHeader> _reports = [];
  List<ReportCardHeader> get reports => _reports;

  ReportCardDetail? _currentDetail;
  ReportCardDetail? get currentDetail => _currentDetail;
  int? _currentDetailId;

  String getPdfUrl(int raporId) => repository.getPdfUrl(raporId);

  Future<Uint8List> generatePdf(
    ReportCardDetail detail,
    ReportCardHeader? header,
    UserProfile? user,
  ) {
    return repository.generatePdf(detail, header, user);
  }

  Future<Uint8List?> loadCachedReportPdf(String token, int raporId) {
    return repository.loadCachedReportPdf(token, raporId);
  }

  Future<Uint8List> getReportPdf(
    String token,
    int raporId, {
    bool forceRefresh = false,
  }) {
    return repository.getReportPdf(token, raporId, forceRefresh: forceRefresh);
  }

  Future<void> saveReportPdf(String token, int raporId, Uint8List pdfBytes) {
    return repository.saveReportPdf(token, raporId, pdfBytes);
  }

  Future<void> fetchReportList(
    String token, {
    bool forceRefresh = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reports = await repository.getReportList(
        token,
        forceRefresh: forceRefresh,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchReportDetail(
    String token,
    int raporId, {
    bool forceRefresh = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    if (_currentDetailId != raporId) {
      _currentDetail = null;
      _currentDetailId = raporId;
    }
    notifyListeners();

    try {
      _currentDetail = await repository.getReportDetail(
        token,
        raporId,
        forceRefresh: forceRefresh,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
