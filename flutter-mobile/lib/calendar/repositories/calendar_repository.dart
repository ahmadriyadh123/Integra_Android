import '../models/calendar_model.dart';
import '../services/calendar_service.dart';

class CalendarRepository {
  final CalendarService apiService;

  CalendarRepository({required this.apiService});

  Future<List<CalendarItem>> getCalendars(String token) async {
    final data = await apiService.fetchCalendars(token);
    final List<dynamic> raw = data['calendars'] as List<dynamic>? ?? [];
    return raw
        .map((e) => CalendarItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
