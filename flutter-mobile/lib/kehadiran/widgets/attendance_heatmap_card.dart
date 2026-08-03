import 'package:flutter/material.dart';

class AttendanceHeatmapCard extends StatelessWidget {
  final int totalDays;
  final List<Widget> heatmapCells;

  const AttendanceHeatmapCard({
    super.key,
    required this.totalDays,
    required this.heatmapCells,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Peta Presensi Bulanan ($totalDays Hari)',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              const Text(
                'Klik tanggal untuk detail',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 5,
            childAspectRatio: 1.25,
            children: heatmapCells,
          ),
        ],
      ),
    );
  }
}