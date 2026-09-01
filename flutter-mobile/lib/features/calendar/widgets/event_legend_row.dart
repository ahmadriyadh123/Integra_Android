import 'package:flutter/material.dart';

class EventLegendRow extends StatelessWidget {
  const EventLegendRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: const [
        _LegendItem(color: Color(0xFFEF4444), label: 'Libur Nasional'),
        _LegendItem(color: Color(0xFF0284C7), label: 'Ujian / CBT'),
        _LegendItem(color: Color(0xFF059669), label: 'Kegiatan Sekolah'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}