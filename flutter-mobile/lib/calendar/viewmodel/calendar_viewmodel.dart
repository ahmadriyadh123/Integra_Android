import 'package:flutter/material.dart';
import '../models/calendar_model.dart';
import '../repositories/calendar_repository.dart';

class CalendarViewModel extends ChangeNotifier {
  final CalendarRepository repository;

  CalendarViewModel({required this.repository});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<CalendarItem> _calendars = [];
  List<CalendarItem> get calendars => _calendars;

  bool get hasData => _calendars.isNotEmpty;

  Future<void> fetchCalendars(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _calendars = await repository.getCalendars(token);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _calendars = [];
    _errorMessage = null;
    _isLoading = false;
  }
}
