import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/rapor_model.dart';
import '../repositories/rapor_repository.dart';
import '../../auth/models/auth_model.dart';

class RaporViewModel extends ChangeNotifier {
  final RaporRepository repository;

  RaporViewModel({required this.repository});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ReportCardHeader> _reports = [];
  List<ReportCardHeader> get reports => _reports;

  ReportCardDetail? _currentDetail;
  ReportCardDetail? get currentDetail => _currentDetail;

  String getPdfUrl(int raporId) => repository.getPdfUrl(raporId);

  Future<Uint8List> generatePdf(
    ReportCardDetail detail,
    ReportCardHeader? header,
    UserProfile? user,
  ) {
    return repository.generatePdf(detail, header, user);
  }

  Future<void> fetchReportList(String token, {bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reports = await repository.getReportList(token, forceRefresh: forceRefresh);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchReportDetail(String token, int raporId, {bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    _currentDetail = null;
    notifyListeners();

    try {
      _currentDetail = await repository.getReportDetail(token, raporId, forceRefresh: forceRefresh);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
