import 'package:flutter/material.dart';

class AttendanceHeader extends StatelessWidget {
  final bool showBackButton;

  const AttendanceHeader({
    super.key,
    required this.showBackButton,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBackButton)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () => Navigator.maybePop(context),
              borderRadius: BorderRadius.circular(50),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rekap Presensi Siswa',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Sinkron Odoo: hr.attendance',
              style: TextStyle(
                fontSize: 9,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AttendanceMonthFilter extends StatelessWidget {
  final String? activeMonthLabel;
  final List<String> availableMonths;
  final ValueChanged<String?> onMonthChanged;

  const AttendanceMonthFilter({
    super.key,
    required this.activeMonthLabel,
    required this.availableMonths,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (availableMonths.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedValue = availableMonths.contains(activeMonthLabel)
        ? activeMonthLabel
        : availableMonths.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Color(0xFF475569),
          ),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
          onChanged: onMonthChanged,
          items: availableMonths.map((month) {
            return DropdownMenuItem<String>(
              value: month,
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    size: 14,
                    color: Color(0xFF0284C7),
                  ),
                  const SizedBox(width: 8),
                  Text(month),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
