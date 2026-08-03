import 'package:flutter/material.dart';

class AttendanceHeader extends StatelessWidget {
  final bool showBackButton;
  final String activeMonthLabel;
  final List<String> availableMonths;
  final ValueChanged<String?> onMonthChanged;

  const AttendanceHeader({
    super.key,
    required this.showBackButton,
    required this.activeMonthLabel,
    required this.availableMonths,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: activeMonthLabel,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: Color(0xFF1E293B),
              ),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              onChanged: onMonthChanged,
              items: availableMonths.map((m) {
                return DropdownMenuItem<String>(
                  value: m,
                  child: Text(m),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}