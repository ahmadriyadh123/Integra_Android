import 'package:flutter/material.dart';

class TeacherInfoCard extends StatelessWidget {
  final String teacherName;

  const TeacherInfoCard({super.key, required this.teacherName});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF059669);

    // Ambil inisial nama pertama
    final initial = teacherName.isNotEmpty ? teacherName[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            child: Text(
              initial,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GURU PENGAMPU',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  teacherName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded, color: primaryColor, size: 20),
          ),
        ],
      ),
    );
  }
}