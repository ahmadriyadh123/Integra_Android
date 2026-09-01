import 'package:flutter/material.dart';

class QuizResultCard extends StatelessWidget {
  final int score;
  final bool isPassed;
  final int correctAnswersCount;
  final int totalQuestions;
  final int answeredCount;

  const QuizResultCard({
    super.key,
    required this.score,
    required this.isPassed,
    required this.correctAnswersCount,
    required this.totalQuestions,
    required this.answeredCount,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF059669);
    const Color primaryLightColor = Color(0xFFECFDF5);
    const Color dangerColor = Color(0xFFE11D48);
    const Color dangerLightColor = Color(0xFFFFF1F2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isPassed ? primaryLightColor : dangerLightColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPassed ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
              color: isPassed ? primaryColor : dangerColor,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isPassed ? 'Selamat! Anda Lulus Kuis' : 'Belum Mencapai Batas Kelulusan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isPassed ? primaryColor : dangerColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPassed ? 'Kemampuan Anda pada Aturan Sinus sangat baik!' : 'Nilai minimum kelulusan kuis adalah 70.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            '$score',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              letterSpacing: -1,
            ),
          ),
          const Text(
            'SKOR AKHIR DARI 100',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatPill('Benar', '$correctAnswersCount', const Color(0xFFECFDF5), primaryColor),
              const SizedBox(width: 10),
              _buildStatPill('Salah', '${totalQuestions - correctAnswersCount}', dangerLightColor, dangerColor),
              const SizedBox(width: 10),
              _buildStatPill('Terjawab', '$answeredCount/$totalQuestions', const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9, color: textColor.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}