import 'package:flutter/material.dart';

class HomeAnnouncementCard extends StatelessWidget {
  final String title;
  final String date;
  final String description;
  final VoidCallback onTap;

  const HomeAnnouncementCard({
    super.key,
    required this.title,
    required this.date,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF059669);
    const Color darkSlate = Color(0xFF0F172A);
    const Color textSlate = Color(0xFF475569);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PENGUMUMAN SEKOLAH',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: primaryTeal,
                    ),
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 10,
                    color: textSlate,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: darkSlate,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 11,
                color: textSlate,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}