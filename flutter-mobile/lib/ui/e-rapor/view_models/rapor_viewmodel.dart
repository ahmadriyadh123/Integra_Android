import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/services/core/stale_while_revalidate.dart';
import 'package:flutter_application_1/utils/user_friendly_error.dart';
import '../../../data/model/e-rapor/rapor_model.dart';
import '../../../data/repositories/e-rapor/rapor_repository.dart';
import '../../../data/model/auth/auth_model.dart';

class RaporViewModel extends ChangeNotifier with StaleWhileRevalidateMixin {
  final RaporRepository repository;

  RaporViewModel({required this.repository});

  String? get lastSyncError => repository.lastSyncError == null
      ? null
      : userFriendlyError(repository.lastSyncError!);

  // isLoading dan isRefreshing disediakan oleh StaleWhileRevalidateMixin

  String? _errorMessage;
  String? get errorMessage =>
      _errorMessage == null ? null : userFriendlyError(_errorMessage!);

  // ── Daftar rapor ────────────────────────────────────────────────────────────

  List<ReportCardHeader> _reports = [];
  List<ReportCardHeader> get reports => _reports;

  Future<void> fetchReportList(String token, {bool forceRefresh = false}) =>
      swr<List<ReportCardHeader>>(
        hasStale: _reports.isNotEmpty,
        forceRefresh: forceRefresh,
        load: () => repository.loadCachedReportList(token),
        fetch: () => repository.getReportList(token, forceRefresh: true),
        onData: (data) {
          _reports = data;
          _errorMessage = null;
        },
        onError: (e) {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        },
      );

  // ── Detail rapor ─────────────────────────────────────────────────────────────

  ReportCardDetail? _currentDetail;
  ReportCardDetail? get currentDetail => _currentDetail;
  int? _currentDetailId;

  Future<void> fetchReportDetail(
    String token,
    int raporId, {
    bool forceRefresh = false,
  }) {
    if (_currentDetailId != raporId) {
      _currentDetail = null;
      _currentDetailId = raporId;
    }
    return swr<ReportCardDetail>(
      hasStale: _currentDetail != null && _currentDetailId == raporId,
      forceRefresh: forceRefresh,
      load: () => repository.loadCachedReportDetail(token, raporId),
      fetch: () => repository.getReportDetail(token, raporId, forceRefresh: true),
      onData: (data) {
        _currentDetail = data;
        _currentDetailId = raporId;
        _errorMessage = null;
      },
      onError: (e) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      },
    );
  }

  // ── PDF ──────────────────────────────────────────────────────────────────────

  String getPdfUrl(int raporId) => repository.getPdfUrl(raporId);

  Future<Uint8List> generatePdf(
    ReportCardDetail detail,
    ReportCardHeader? header,
    UserProfile? user,
  ) => repository.generatePdf(detail, header, user);

  Future<Uint8List?> loadCachedReportPdf(String token, int raporId) =>
      repository.loadCachedReportPdf(token, raporId);

  Future<Uint8List> getReportPdf(
    String token,
    int raporId, {
    bool forceRefresh = false,
  }) => repository.getReportPdf(token, raporId, forceRefresh: forceRefresh);

  Future<void> saveReportPdf(String token, int raporId, Uint8List pdfBytes) =>
      repository.saveReportPdf(token, raporId, pdfBytes);
}
