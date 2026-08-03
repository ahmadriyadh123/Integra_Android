import 'package:flutter/material.dart';

class RaporSubjectCard extends StatelessWidget {
  final String subjectName;
  final String teacherName;
  final int knowledgeScore;
  final int skillScore;
  final String predicate;

  const RaporSubjectCard({
    super.key,
    required this.subjectName,
    required this.teacherName,
    required this.knowledgeScore,
    required this.skillScore,
    required this.predicate,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF059669);
    const Color darkSlate = Color(0xFF0F172A);
    const Color textSlate = Color(0xFF475569);
    const Color borderSlate = Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSlate),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subjectName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: darkSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      teacherName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: textSlate,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                alignment: Alignment.center,
                child: Text(
                  predicate,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: primaryTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScoreItem('Pengetahuan (KI-3)', '$knowledgeScore'),
              _buildScoreItem('Keterampilan (KI-4)', '$skillScore'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, String score) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        Text(
          score,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}