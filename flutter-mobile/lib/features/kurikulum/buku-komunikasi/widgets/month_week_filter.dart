import 'package:flutter/material.dart';

class MonthWeekFilter extends StatelessWidget {
  final String selectedMonth;
  final String selectedWeek;
  final List<String> months;
  final List<String> weeks;
  final ValueChanged<String?> onMonthChanged;
  final ValueChanged<String?> onWeekChanged;

  const MonthWeekFilter({
    super.key,
    required this.selectedMonth,
    required this.selectedWeek,
    required this.months,
    required this.weeks,
    required this.onMonthChanged,
    required this.onWeekChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDropdown(
            value: selectedMonth,
            items: months,
            icon: Icons.calendar_month,
            onChanged: onMonthChanged,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDropdown(
            value: selectedWeek,
            items: weeks,
            icon: Icons.view_week,
            onChanged: onWeekChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF475569), size: 18),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  Icon(icon, size: 14, color: const Color(0xFF059669)),
                  const SizedBox(width: 8),
                  Text(item),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}