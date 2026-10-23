import 'package:flutter/material.dart';
import 'package:flutter_application_1/utils/user_friendly_error.dart';
import 'package:flutter_application_1/domain/models/cbt_answer.dart';
import '../../../../data/model/kurikulum/cbt/cbt_model.dart';
import '../../../../data/repositories/kurikulum/cbt/cbt_repository.dart';

class CbtViewModel extends ChangeNotifier {
  final CbtRepository repository;

  CbtViewModel({required this.repository});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage =>
      _errorMessage == null ? null : userFriendlyError(_errorMessage!);

  List<CbtExamSchedule> _exams = [];
  List<CbtExamSchedule> get exams => _exams;

  Future<void> fetchCbtSchedules(
    String token, {
    bool forceRefresh = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _exams = await repository.getCbtSchedules(
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

  void reset() {
    _exams = [];
    _errorMessage = null;
    _isLoading = false;
  }

  Future<bool> verifyToken(
    String token,
    int jadwalId,
    String tokenInput,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isSuccess = await repository.verifyToken(
        token,
        jadwalId,
        tokenInput,
      );
      return isSuccess;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CbtExamData> getExamQuestions(String token, int jadwalId) {
    return repository.getExamQuestions(token, jadwalId);
  }

  Future<CbtSubmitResult> submitExam(
    String token,
    int jadwalId,
    List<CbtAnswer> answers,
    String? waktuMulai,
  ) => repository.submitExam(token, jadwalId, answers, waktuMulai);
}
