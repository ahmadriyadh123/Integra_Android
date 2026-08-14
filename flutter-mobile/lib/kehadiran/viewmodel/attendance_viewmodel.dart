import 'package:flutter/material.dart';
import '../models/attendance_record.dart';
import '../repositories/attendance_repository.dart';

class AttendanceViewModel extends ChangeNotifier {
  final AttendanceRepository repository;

  AttendanceViewModel({required this.repository});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<AttendanceRecord> _allRecords = [];
  
  String _activeMonthLabel = 'Juli 2026';
  String get activeMonthLabel => _activeMonthLabel;

  final List<String> availableMonths = [
    'Juli 2026',
    'Agustus 2026',
    'September 2026',
  ];

  void setActiveMonth(String? newMonth) {
    if (newMonth != null) {
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
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Helper Metode UI ---
  List<AttendanceRecord> get filteredRecords {
    // In production, this would filter by _activeMonthLabel
    return _allRecords;
  }

  // Statistics for Summary
  int get totalPresent => filteredRecords.where((r) => r.hadir > 0).length;
  int get totalSick => filteredRecords.where((r) => r.sakit > 0).length;
  int get totalPermit => filteredRecords.where((r) => r.izin > 0).length;
  int get totalAlpha => filteredRecords.where((r) => r.alpha > 0).length;
  
  double get attendancePercentage {
    if (filteredRecords.isEmpty) return 0;
    return (totalPresent / filteredRecords.length) * 100;
  }

  Map<DateTime, List<AttendanceRecord>> get groupedWeeks {
    final Map<DateTime, List<AttendanceRecord>> weeks = {};
    for (var record in filteredRecords) {
      final monday = record.date.subtract(Duration(days: record.date.weekday - 1));
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

  String getMonthName(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[date.month - 1];
  }

  String getWeekdayName(int weekday) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return days[weekday - 1];
  }

  List<Widget> generateHeatmapCells() {
    // Mocking 31 days for a calendar-like view
    return List.generate(31, (index) {
      final dayNum = index + 1;
      
      // Determine color based on record if available
      Color cellBg = const Color(0xFFF1F5F9); // Default empty
      Color textColor = const Color(0xFF64748B);

      // Simple mock logic for specific days matching records
      if (dayNum <= filteredRecords.length) {
        final record = filteredRecords[dayNum - 1];
        if (record.alpha > 0) {
          cellBg = const Color(0xFFFEF2F2);
          textColor = const Color(0xFFDC2626);
        } else if (record.sakit > 0) {
          cellBg = const Color(0xFFF0F9FF);
          textColor = const Color(0xFF0284C7);
        } else if (record.izin > 0) {
          cellBg = const Color(0xFFFEF3C7);
          textColor = const Color(0xFFD97706);
        } else {
          cellBg = const Color(0xFFECFDF5);
          textColor = const Color(0xFF059669);
        }
      }

      return Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: cellBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '$dayNum',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      );
    });
  }
}
