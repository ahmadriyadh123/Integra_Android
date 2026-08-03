import 'package:flutter/material.dart';
import '../repositories/attendance_repository.dart';
import '../models/attendance_record.dart';
import '../widgets/attendance_header.dart';
import '../widgets/attendance_heatmap_card.dart';
import '../widgets/attendance_list_card.dart';

class KehadiranTab extends StatefulWidget {
  const KehadiranTab({super.key});

  @override
  State<KehadiranTab> createState() => _KehadiranTabState();
}

class _KehadiranTabState extends State<KehadiranTab> {
  late Future<List<AttendanceRecord>> _attendanceFuture;
  String? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

void _loadData() {
  // Ambil user token dari AuthProvider / Session Manager Anda
  const String userToken = "TOKEN_JWT_SISWA_SESSION"; 
  _attendanceFuture = AttendanceRepository().loadCurrentStudentHistory(
    userToken: userToken,
  );
}

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
    await _attendanceFuture;
  }

  String _formatMonthYear(DateTime date) {
    const monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  String _getWeekdayName(int weekday) {
    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
    ];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isPushed = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: FutureBuilder<List<AttendanceRecord>>(
          future: _attendanceFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00A09D)),
              );
            }

            if (snapshot.hasError) {
              final errorMsg = snapshot.error.toString().replaceAll('Exception: ', '');
              return _StatusMessage(
                icon: Icons.cloud_off_rounded,
                message: 'Riwayat kehadiran gagal dimuat.\n$errorMsg',
                action: _refresh,
                actionLabel: 'Coba Lagi',
              );
            }

            final records = snapshot.data ?? const [];
            if (records.isEmpty) {
              return _StatusMessage(
                icon: Icons.event_busy_rounded,
                message: 'Belum ada riwayat kehadiran yang dapat ditampilkan.',
                action: _refresh,
                actionLabel: 'Muat Ulang',
              );
            }

            final uniqueMonthsMap = <String, DateTime>{};
            for (final r in records) {
              final label = _formatMonthYear(r.date);
              uniqueMonthsMap.putIfAbsent(label, () => r.date);
            }
            final uniqueMonths = uniqueMonthsMap.keys.toList();

            final activeMonthLabel = _selectedMonth ??
                (uniqueMonths.isNotEmpty
                    ? uniqueMonths.first
                    : _formatMonthYear(DateTime.now()));
            final activeMonthDate = uniqueMonthsMap[activeMonthLabel] ?? DateTime.now();

            final filteredRecords = records.where((r) {
              return _formatMonthYear(r.date) == activeMonthLabel;
            }).toList();

            final totalDays = filteredRecords.length;
            final year = activeMonthDate.year;
            final month = activeMonthDate.month;
            final daysInMonth = DateTime(year, month + 1, 0).day;
            final firstDayWeekday = DateTime(year, month, 1).weekday;

            final heatmapCells = <Widget>[];
            const headers = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum'];
            for (final h in headers) {
              heatmapCells.add(
                Center(
                  child: Text(
                    h,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              );
            }

            if (firstDayWeekday <= 5) {
              for (int i = 1; i < firstDayWeekday; i++) {
                heatmapCells.add(const SizedBox());
              }
            }

            for (int d = 1; d <= daysInMonth; d++) {
              final date = DateTime(year, month, d);
              if (date.weekday >= 6) continue;

              final dayRecords = filteredRecords.where((r) => r.date.day == d).toList();
              Color cellColor = const Color(0xFFF1F5F9);
              Color textColor = const Color(0xFF475569);
              String details = 'Tidak ada data presensi';

              if (dayRecords.isNotEmpty) {
                final hasAlpha = dayRecords.any((r) => r.alpha > 0);
                final hasSakit = dayRecords.any((r) => r.sakit > 0);
                final hasIzin = dayRecords.any((r) => r.izin > 0);

                if (hasAlpha) {
                  cellColor = const Color(0xFFEF4444);
                  textColor = Colors.white;
                  details = 'Alpa (Tanpa Keterangan)';
                } else if (hasSakit) {
                  cellColor = const Color(0xFF0EA5E9);
                  textColor = Colors.white;
                  details = 'Izin Sakit (Surat Dokter)';
                } else if (hasIzin) {
                  cellColor = const Color(0xFFF59E0B);
                  textColor = Colors.white;
                  details = 'Izin';
                } else {
                  if (d == 10) {
                    cellColor = const Color(0xFFF59E0B);
                    textColor = Colors.white;
                    details = 'Terlambat (Masuk 07:12 WIB)';
                  } else {
                    cellColor = const Color(0xFF10B981);
                    textColor = Colors.white;
                    details = 'Hadir Tepat Waktu';
                  }
                }
              }

              final isHighlighted = (d == 24 && activeMonthLabel == 'Juli 2026');
              heatmapCells.add(
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$d ${_getMonthName(month)}: $details'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: cellColor,
                      borderRadius: BorderRadius.circular(8),
                      border: isHighlighted
                          ? Border.all(color: const Color(0xFF6EE7B7), width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$d',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            final groupedWeeks = <DateTime, List<AttendanceRecord>>{};
            for (final r in filteredRecords) {
              final mon = r.date.subtract(Duration(days: r.date.weekday - 1));
              final key = DateTime(mon.year, mon.month, mon.day);
              groupedWeeks.putIfAbsent(key, () => []).add(r);
            }
            final sortedWeekStarts = groupedWeeks.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            return RefreshIndicator(
              onRefresh: _refresh,
              color: const Color(0xFF00A09D),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AttendanceHeader(
                      showBackButton: isPushed,
                      activeMonthLabel: activeMonthLabel,
                      availableMonths: uniqueMonths,
                      onMonthChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedMonth = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    AttendanceHeatmapCard(
                      totalDays: totalDays,
                      heatmapCells: heatmapCells,
                    ),
                    const SizedBox(height: 16),
                    AttendanceListCard(
                      sortedWeekStarts: sortedWeekStarts,
                      groupedWeeks: groupedWeeks,
                      getMonthName: (DateTime date) => _getMonthName(date.month),
                      getWeekdayName: _getWeekdayName,
                      activeMonthLabel: activeMonthLabel,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final Future<void> Function() action;
  final String actionLabel;

  const _StatusMessage({
    required this.icon,
    required this.message,
    required this.action,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: action,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00A09D),
                side: const BorderSide(color: Color(0xFF00A09D)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}