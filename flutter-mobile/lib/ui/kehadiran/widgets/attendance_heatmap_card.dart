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
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF334155),
                ),
              ),
              const Text(
                'STATUS HARI',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _HeatmapLegendItem('Hadir', Color(0xFF10B981)),
              _HeatmapLegendItem('Sakit', Color(0xFF0EA5E9)),
              _HeatmapLegendItem('Izin', Color(0xFFF59E0B)),
              _HeatmapLegendItem('Alpa', Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 5,
            childAspectRatio: 1.05,
            children: heatmapCells,
          ),
        ],
      ),
    );
  }
}

class _HeatmapLegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _HeatmapLegendItem(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}