import 'package:flutter/material.dart';
import '../models/weekly_plan_model.dart';
import '../repositories/weekly_plan_repository.dart';

class WeeklyPlanViewModel extends ChangeNotifier {
  final WeeklyPlanRepository repository;

  WeeklyPlanViewModel({required this.repository});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<WeeklyPlanItem> _items = [];
  List<WeeklyPlanItem> get items => _items;
  bool get hasData => _items.isNotEmpty;

  Future<void> fetchList(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await repository.getWeeklyPlanList(token);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kembalikan URL PDF untuk plan tertentu
  String getPdfUrl(int planId) => repository.getPdfUrl(planId);

  void reset() {
    _items = [];
    _errorMessage = null;
    _isLoading = false;
  }
}
