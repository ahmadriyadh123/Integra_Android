import 'package:flutter/material.dart';

class RaporNotesCard extends StatelessWidget {
  final String teacherNotes;
  final String statusText;

  const RaporNotesCard({
    super.key,
    required this.teacherNotes,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF059669);
    const Color darkSlate = Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('👩‍🏫', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text(
                'Catatan Wali Kelas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF065F46),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '"$teacherNotes"',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: darkSlate,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFA7F3D0)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status Keputusan:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF065F46),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryTeal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}