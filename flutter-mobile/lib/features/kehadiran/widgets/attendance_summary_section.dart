import 'package:flutter/material.dart';

class AttendanceSummarySection extends StatelessWidget {
  final int totalPresent;
  final int totalSick;
  final int totalPermit;
  final int totalAlpha;

  const AttendanceSummarySection({
    super.key,
    required this.totalPresent,
    required this.totalSick,
    required this.totalPermit,
    required this.totalAlpha,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStatItem(
          'HADIR',
          totalPresent,
          const Color(0xFF059669),
          Icons.check_circle_outline,
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          'SAKIT',
          totalSick,
          const Color(0xFF0284C7),
          Icons.local_hospital_outlined,
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          'IZIN',
          totalPermit,
          const Color(0xFFF59E0B),
          Icons.info_outline,
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          'ALPA',
          totalAlpha,
          const Color(0xFFEF4444),
          Icons.cancel_outlined,
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
