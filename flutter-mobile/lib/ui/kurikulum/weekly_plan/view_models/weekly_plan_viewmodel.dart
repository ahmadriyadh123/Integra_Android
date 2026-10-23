import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/services/core/stale_while_revalidate.dart';
import 'package:flutter_application_1/utils/user_friendly_error.dart';
import '../../../../data/model/kurikulum/weekly_plan/weekly_plan_model.dart';
import '../../../../data/model/kurikulum/weekly_plan/weekly_plan_detail_model.dart';
import '../../../../data/repositories/kurikulum/weekly_plan/weekly_plan_repository.dart';

class WeeklyPlanViewModel extends ChangeNotifier with StaleWhileRevalidateMixin {
  final WeeklyPlanRepository repository;

  WeeklyPlanViewModel({required this.repository});

  String? get lastSyncError => repository.lastSyncError == null
      ? null
      : userFriendlyError(repository.lastSyncError!);

  // isLoading dan isRefreshing disediakan oleh StaleWhileRevalidateMixin

  String? _errorMessage;
  String? get errorMessage =>
      _errorMessage == null ? null : userFriendlyError(_errorMessage!);

  List<WeeklyPlanItem> _items = [];
  List<WeeklyPlanItem> get items => _items;
  bool get hasData => _items.isNotEmpty;

  // ── List ─────────────────────────────────────────────────────────────────────

  Future<void> fetchList(String token, {bool forceRefresh = false}) =>
      swr<List<WeeklyPlanItem>>(
        hasStale: _items.isNotEmpty,
        forceRefresh: forceRefresh,
        load: () => repository.loadCachedWeeklyPlanList(token),
        fetch: () => repository.getWeeklyPlanList(token, forceRefresh: true),
        onData: (data) {
          _items = data;
          _errorMessage = null;
        },
        onError: (e) {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        },
      );

  // ── Detail ───────────────────────────────────────────────────────────────────

  bool _isLoadingDetail = false;
  bool get isLoadingDetail => _isLoadingDetail;

  String? _detailErrorMessage;
  String? get detailErrorMessage => _detailErrorMessage == null
      ? null
      : userFriendlyError(_detailErrorMessage!);

  WeeklyPlanDetailModel? _selectedPlanDetail;
  WeeklyPlanDetailModel? get selectedPlanDetail => _selectedPlanDetail;

  Future<void> fetchDetail(int planId, String token) async {
    _isLoadingDetail = true;
    _detailErrorMessage = null;
    notifyListeners();
    try {
      _selectedPlanDetail =
          await repository.getWeeklyPlanDetail(planId, token);
    } catch (e) {
      _detailErrorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  // ── PDF ──────────────────────────────────────────────────────────────────────

  bool _isGeneratingPdf = false;
  bool get isGeneratingPdf => _isGeneratingPdf;

  String? _pdfError;
  String? get pdfError =>
      _pdfError == null ? null : userFriendlyError(_pdfError!);

  Uint8List? _pdfBytes;
  Uint8List? get pdfBytes => _pdfBytes;

  Future<void> fetchPdfFile(
    int planId,
    String token, {
    bool forceRefresh = false,
  }) async {
    _isGeneratingPdf = true;
    _pdfError = null;
    notifyListeners();
    try {
      _pdfBytes = await repository.getWeeklyPlanPdfFile(
        planId,
        token,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      _pdfError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isGeneratingPdf = false;
      notifyListeners();
    }
  }

  void clearPdfState() {
    _pdfBytes = null;
    _pdfError = null;
    _isGeneratingPdf = false;
  }

  void reset() {
    _items = [];
    _errorMessage = null;
    _selectedPlanDetail = null;
    _detailErrorMessage = null;
    _isLoadingDetail = false;
  }
}
