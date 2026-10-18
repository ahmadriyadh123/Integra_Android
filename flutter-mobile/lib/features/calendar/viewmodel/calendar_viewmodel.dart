import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/stale_while_revalidate.dart';
import 'package:flutter_application_1/services/user_friendly_error.dart';
import '../models/calendar_model.dart';
import '../repositories/calendar_repository.dart';

class CalendarViewModel extends ChangeNotifier with StaleWhileRevalidateMixin {
  final CalendarRepository repository;

  CalendarViewModel({required this.repository});

  // isLoading dan isRefreshing disediakan oleh StaleWhileRevalidateMixin

  String? _errorMessage;
  String? get errorMessage =>
      _errorMessage == null ? null : userFriendlyError(_errorMessage!);

  List<CalendarItem> _calendars = [];
  List<CalendarItem> get calendars => _calendars;
  bool get hasData => _calendars.isNotEmpty;

  Future<void> fetchCalendars(String token, {bool forceRefresh = false}) =>
      swr<List<CalendarItem>>(
        hasStale: _calendars.isNotEmpty,
        forceRefresh: forceRefresh,
        load: () => repository.loadCachedCalendars(token),
        fetch: () => repository.getCalendars(token, forceRefresh: true),
        onData: (data) {
          _calendars = data;
          _errorMessage = null;
        },
        onError: (e) {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        },
      );

  void reset() {
    _calendars = [];
    _errorMessage = null;
  }
}
