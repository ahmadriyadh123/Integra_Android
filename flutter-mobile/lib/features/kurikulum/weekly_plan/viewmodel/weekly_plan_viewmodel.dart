import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/user_friendly_error.dart';
import '../models/weekly_plan_model.dart';
import '../models/weekly_plan_detail_model.dart';
import '../repositories/weekly_plan_repository.dart';

class WeeklyPlanViewModel extends ChangeNotifier {
  final WeeklyPlanRepository repository;

  WeeklyPlanViewModel({required this.repository});
  String? get lastSyncError => repository.lastSyncError == null
      ? null
      : userFriendlyError(repository.lastSyncError!);

  // State List
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage =>
      _errorMessage == null ? null : userFriendlyError(_errorMessage!);

  List<WeeklyPlanItem> _items = [];
  List<WeeklyPlanItem> get items => _items;
  bool get hasData => _items.isNotEmpty;

  // State Detail
  bool _isLoadingDetail = false;
  bool get isLoadingDetail => _isLoadingDetail;

  String? _detailErrorMessage;
  String? get detailErrorMessage => _detailErrorMessage == null
      ? null
      : userFriendlyError(_detailErrorMessage!);

  WeeklyPlanDetailModel? _selectedPlanDetail;
  WeeklyPlanDetailModel? get selectedPlanDetail => _selectedPlanDetail;

  // State PDF Viewer
  bool _isGeneratingPdf = false;
  bool get isGeneratingPdf => _isGeneratingPdf;

  String? _pdfError;
  String? get pdfError => _pdfError == null ? null : userFriendlyError(_pdfError!);

  Uint8List? _pdfBytes;
  Uint8List? get pdfBytes => _pdfBytes;

  // Fetch List
  Future<void> fetchList(String token, {bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _items = await repository.getWeeklyPlanList(
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

  // Fetch Detail
  Future<void> fetchDetail(int planId, String token) async {
    _isLoadingDetail = true;
    _detailErrorMessage = null;
    notifyListeners();
    try {
      _selectedPlanDetail = await repository.getWeeklyPlanDetail(planId, token);
    } catch (e) {
      _detailErrorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

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
    _isLoading = false;
    _selectedPlanDetail = null;
    _detailErrorMessage = null;
    _isLoadingDetail = false;
  }
}
