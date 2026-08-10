import 'package:flutter/material.dart';
import '../repositories/cbt_repository.dart';

class CbtViewModel extends ChangeNotifier {
  final CbtRepository repository;

  CbtViewModel({required this.repository});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Map<String, dynamic>> _exams = [];
  List<Map<String, dynamic>> get exams => _exams;

  Future<void> fetchCbtSchedules(String token, {bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _exams = await repository.getCbtSchedules(token);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _exams = [];
    _errorMessage = null;
    _isLoading = false;
  }
}
