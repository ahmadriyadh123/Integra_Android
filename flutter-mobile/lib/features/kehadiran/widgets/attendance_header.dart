import 'package:flutter/material.dart';
import '../../widgets/custom_dropdown_below.dart';

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

    final selectedMonth = availableMonths.contains(activeMonthLabel)
        ? activeMonthLabel
        : availableMonths.first;
    return _buildDropdown(
      value: selectedMonth,
      items: availableMonths,
      icon: Icons.calendar_month,
      onChanged: onMonthChanged,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return CustomDropdownBelowField(
      value: value,
      hint: '-- Pilih bulan --',
      items: items,
      onChanged: onChanged,
      prefixIcon: icon,
    );
  }
}
