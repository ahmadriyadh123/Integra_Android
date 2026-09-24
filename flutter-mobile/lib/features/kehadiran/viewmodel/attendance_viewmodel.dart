import 'package:flutter/material.dart';
import '../models/attendance_record.dart';
import '../repositories/attendance_repository.dart';

class AttendanceViewModel extends ChangeNotifier {
  final AttendanceRepository repository;

  AttendanceViewModel({required this.repository});

  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<AttendanceRecord> _allRecords = [];

  String? _activeMonthLabel;
  String? get activeMonthLabel => _activeMonthLabel;

  List<String> get availableMonths {
    final year = _allRecords.isEmpty
        ? DateTime.now().year
        : _allRecords.map((record) => record.date.year).reduce((a, b) => a > b ? a : b);
    return _monthNames.map((month) => '$month $year').toList();
  }

  void setActiveMonth(String? newMonth) {
    if (newMonth != null && newMonth != _activeMonthLabel) {
      _activeMonthLabel = newMonth;
      notifyListeners();
    }
  }

  Future<void> fetchAttendance(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allRecords = await repository.getAttendanceHistory(token);
      _syncActiveMonth();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _syncActiveMonth() {
    final months = availableMonths;
    if (months.isEmpty) {
      _activeMonthLabel = null;
      return;
    }
    if (_activeMonthLabel == null || !months.contains(_activeMonthLabel)) {
      if (_allRecords.isNotEmpty) {
        final latestRecord = _allRecords.reduce(
          (current, record) => record.date.isAfter(current.date) ? record : current,
        );
        _activeMonthLabel = monthLabelFor(latestRecord.date);
      } else {
        _activeMonthLabel = months.first;
      }
    }
  }

  String monthLabelFor(DateTime date) =>
      '${getMonthName(date)} ${date.year}';

  DateTime? get activeMonthDate {
    final label = _activeMonthLabel;
    if (label == null) return null;

    final parts = label.split(' ');
    if (parts.length < 2) return null;

    final monthIndex = _monthNames.indexOf(parts.first);
    final year = int.tryParse(parts.last);
    if (monthIndex < 0 || year == null) return null;

    return DateTime(year, monthIndex + 1);
  }

  List<AttendanceRecord> get filteredRecords {
    final label = _activeMonthLabel;
    if (label == null) return const [];
    return _allRecords
        .where((record) => monthLabelFor(record.date) == label)
        .toList();
  }

  int get totalPresent => filteredRecords.where((r) => r.hadir > 0).length;
  int get totalSick => filteredRecords.where((r) => r.sakit > 0).length;
  int get totalPermit => filteredRecords.where((r) => r.izin > 0).length;
  int get totalAlpha => filteredRecords.where((r) => r.alpha > 0).length;

  Map<DateTime, List<AttendanceRecord>> get groupedWeeks {
    final Map<DateTime, List<AttendanceRecord>> weeks = {};
    for (var record in filteredRecords) {
      final monday =
          record.date.subtract(Duration(days: record.date.weekday - 1));
      final weekStart = DateTime(monday.year, monday.month, monday.day);

      if (!weeks.containsKey(weekStart)) {
        weeks[weekStart] = [];
      }
      weeks[weekStart]!.add(record);
    }
    return weeks;
  }

  List<DateTime> get sortedWeekStarts {
    final list = groupedWeeks.keys.toList();
    list.sort((a, b) => b.compareTo(a));
    return list;
  }

  String getMonthName(DateTime date) => _monthNames[date.month - 1];

  String getWeekdayName(int weekday) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return days[weekday - 1];
  }

  List<Widget> generateHeatmapCells() {
    final monthDate = activeMonthDate ?? DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(monthDate.year, monthDate.month);
    final recordsByDay = <int, AttendanceRecord>{};
    for (final record in filteredRecords) {
      recordsByDay[record.date.day] = record;
    }

    return List.generate(daysInMonth, (index) {
      final dayNum = index + 1;
      final record = recordsByDay[dayNum];

      Color cellBg = const Color(0xFFE2E8F0);
      Color textColor = const Color(0xFF475569);
      Color borderColor = const Color(0xFFCBD5E1);

      if (record != null) {
        if (record.alpha > 0) {
          cellBg = const Color(0xFFFCA5A5);
          textColor = const Color(0xFF991B1B);
          borderColor = const Color(0xFFEF4444);
        } else if (record.sakit > 0) {
          cellBg = const Color(0xFF7DD3FC);
          textColor = const Color(0xFF075985);
          borderColor = const Color(0xFF0EA5E9);
        } else if (record.izin > 0) {
          cellBg = const Color(0xFFFCD34D);
          textColor = const Color(0xFF92400E);
          borderColor = const Color(0xFFF59E0B);
        } else {
          cellBg = const Color(0xFF6EE7B7);
          textColor = const Color(0xFF065F46);
          borderColor = const Color(0xFF10B981);
        }
      }

      return Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: cellBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Center(
          child: Text(
            '$dayNum',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ),
      );
    });
  }
}
