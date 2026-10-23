import 'package:flutter/material.dart';

import '../../../../data/model/elearning/elearning_model.dart';

class CourseProgressCard extends StatelessWidget {
  final CourseDetail detail;

  const CourseProgressCard({super.key, required this.detail});

  static const _green = Color(0xFF059669);
  static const _textDark = Color(0xFF1E293B);
  static const _textMuted = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final progress = (detail.progressPercent / 100).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progres belajar',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              Text(
                '${detail.progressPercent}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(_green),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${detail.completedSlides} dari ${detail.totalSlides} materi selesai',
            style: const TextStyle(fontSize: 11, color: _textMuted),
          ),
        ],
      ),
    );
  }
}
