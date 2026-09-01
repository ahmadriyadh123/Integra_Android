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

  Future<bool> verifyToken(String token, int jadwalId, String tokenInput) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isSuccess = await repository.verifyToken(token, jadwalId, tokenInput);
      return isSuccess;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getExamQuestions(String token, int jadwalId) async {
    try {
      return await repository.getExamQuestions(token, jadwalId);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitExam(
    String token,
    int jadwalId,
    List<Map<String, dynamic>> answers,
    String? waktuMulai,
  ) async {
    try {
      return await repository.submitExam(token, jadwalId, answers, waktuMulai);
    } catch (e) {
      rethrow;
    }
  }
}

