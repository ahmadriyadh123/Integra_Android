import 'package:flutter/material.dart';

class CbtExamCard extends StatelessWidget {
  final String subject;
  final String examType;
  final String date;
  final String time;
  final int duration;
  final int questionCount;
  final String status;
  final VoidCallback onActionTap;

  const CbtExamCard({
    super.key,
    required this.subject,
    required this.examType,
    required this.date,
    required this.time,
    required this.duration,
    required this.questionCount,
    required this.status,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0284C7);
    const Color successColor = Color(0xFF10B981);
    
    final isActive = status == 'Aktif';
    final isDone = status == 'Selesai';
    final accentColor = isActive ? primaryColor : (isDone ? successColor : Colors.grey);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bagian Header Kartu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    examType,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bagian Informasi Mata Pelajaran
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildIconText(Icons.calendar_month_rounded, date),
                    const SizedBox(width: 16),
                    _buildIconText(Icons.access_time_rounded, time),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildIconText(Icons.timer_outlined, '$duration Menit'),
                    const SizedBox(width: 16),
                    _buildIconText(Icons.format_list_numbered_rounded, '$questionCount Soal'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isActive || isDone ? onActionTap : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDone ? const Color(0xFFECFDF5) : primaryColor,
                      foregroundColor: isDone ? successColor : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      isDone ? 'Lihat Hasil' : (isActive ? 'Mulai Ujian' : 'Belum Dimulai'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }
}