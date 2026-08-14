import 'package:flutter/material.dart';

class AttendanceSummarySection extends StatelessWidget {
  final int totalPresent;
  final int totalSick;
  final int totalPermit;
  final int totalAlpha;
  final double percentage;

  const AttendanceSummarySection({
    super.key,
    required this.totalPresent,
    required this.totalSick,
    required this.totalPermit,
    required this.totalAlpha,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Persentase Kehadiran',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Performa Sangat Baik',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: percentage / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const Icon(Icons.verified_user_rounded, color: Colors.white, size: 32),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatItem('HADIR', totalPresent, const Color(0xFF059669), Icons.check_circle_outline),
            const SizedBox(width: 12),
            _buildStatItem('SAKIT', totalSick, const Color(0xFF0284C7), Icons.local_hospital_outlined),
            const SizedBox(width: 12),
            _buildStatItem('IZIN', totalPermit, const Color(0xFFF59E0B), Icons.info_outline),
            const SizedBox(width: 12),
            _buildStatItem('ALPA', totalAlpha, const Color(0xFFEF4444), Icons.cancel_outlined),
          ],
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
