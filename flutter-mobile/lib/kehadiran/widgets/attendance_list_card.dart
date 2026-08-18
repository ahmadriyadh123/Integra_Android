import 'package:flutter/material.dart';
import '../models/attendance_record.dart';

class AttendanceListCard extends StatelessWidget {
  final List<DateTime> sortedWeekStarts;
  final Map<DateTime, List<AttendanceRecord>> groupedWeeks;
  final String Function(DateTime) getMonthName;
  final String Function(int) getWeekdayName;
  final String? activeMonthLabel;

  const AttendanceListCard({
    super.key,
    required this.sortedWeekStarts,
    required this.groupedWeeks,
    required this.getMonthName,
    required this.getWeekdayName,
    this.activeMonthLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedWeekStarts.length,
        itemBuilder: (context, weekIdx) {
          final weekStart = sortedWeekStarts[weekIdx];
          final weekRecords = groupedWeeks[weekStart]!;
          weekRecords.sort((a, b) => b.date.compareTo(a.date));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                color: const Color(0x80F1F5F9),
              ),
              ...weekRecords.map((record) => _buildAttendanceRow(record)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAttendanceRow(AttendanceRecord record) {
    final dayNum = record.date.day.toString().padLeft(2, '0');
    final weekdayName = getWeekdayName(record.date.weekday);
    final monthName = getMonthName(record.date);

    Color badgeBg;
    Color badgeText;
    Color numCardBg;
    Color numCardText;
    Color numCardBorder;
    String statusLabel;
    Widget subtitleWidget;

    if (record.alpha > 0) {
      badgeBg = const Color(0xFFFEE2E2);
      badgeText = const Color(0xFF991B1B);
      numCardBg = const Color(0xFFFEF2F2);
      numCardText = const Color(0xFFDC2626);
      numCardBorder = const Color(0xFFFEE2E2);
      statusLabel = 'Alpa';
      subtitleWidget = const Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 10, color: Color(0xFFEF4444)),
          SizedBox(width: 4),
          Text(
            'Tanpa Keterangan',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else if (record.sakit > 0) {
      badgeBg = const Color(0xFFE0F2FE);
      badgeText = const Color(0xFF0369A1);
      numCardBg = const Color(0xFFF0F9FF);
      numCardText = const Color(0xFF0284C7);
      numCardBorder = const Color(0xFFE0F2FE);
      statusLabel = 'Izin Sakit';
      subtitleWidget = const Row(
        children: [
          Icon(Icons.file_present_rounded, size: 10, color: Color(0xFF0EA5E9)),
          SizedBox(width: 4),
          Text(
            'Sakit (Surat Dokter Terlampir)',
            style: TextStyle(
              color: Color(0xFF0EA5E9),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else if (record.izin > 0) {
      badgeBg = const Color(0xFFFDE68A);
      badgeText = const Color(0xFF92400E);
      numCardBg = const Color(0xFFFEF3C7);
      numCardText = const Color(0xFFD97706);
      numCardBorder = const Color(0xFFFDE68A);
      statusLabel = 'Izin';
      subtitleWidget = const Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 10, color: Color(0xFFF59E0B)),
          SizedBox(width: 4),
          Text(
            'Izin / Keperluan Keluarga',
            style: TextStyle(
              color: Color(0xFFF59E0B),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else {
      if (record.date.day == 10 && activeMonthLabel == 'Juli 2026') {
        badgeBg = const Color(0xFFFDE68A);
        badgeText = const Color(0xFF92400E);
        numCardBg = const Color(0xFFFEF3C7);
        numCardText = const Color(0xFFD97706);
        numCardBorder = const Color(0xFFFDE68A);
        statusLabel = 'Terlambat';
        subtitleWidget = const Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 10, color: Color(0xFFD97706)),
            SizedBox(width: 4),
            Text(
              'Masuk 07:12 WIB (Terlambat 12 menit)',
              style: TextStyle(
                color: Color(0xFFD97706),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      } else {
        badgeBg = const Color(0xFFD1FAE5);
        badgeText = const Color(0xFF065F46);
        numCardBg = const Color(0xFFECFDF5);
        numCardText = const Color(0xFF059669);
        numCardBorder = const Color(0xFFD1FAE5);
        statusLabel = 'Hadir';
        final checkinMinute = (35 + (record.date.day % 13)).toString().padLeft(2, '0');
        subtitleWidget = Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 10,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(width: 4),
            Text(
              '06:$checkinMinute • 15:30 WIB',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
            ),
          ],
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 0.8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: numCardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: numCardBorder),
                ),
                child: Center(
                  child: Text(
                    dayNum,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: numCardText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$weekdayName, $dayNum $monthName',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  subtitleWidget,
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: badgeText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}