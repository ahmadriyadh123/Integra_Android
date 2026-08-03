import 'package:flutter/material.dart';

class TokenInfoBanner extends StatelessWidget {
  const TokenInfoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.lock_outline_rounded, color: Color(0xFF0284C7), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keamanan Ujian CBT',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0369A1),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Masukkan token 6 digit yang diberikan oleh pengawas ujian di ruang kelas Anda.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}