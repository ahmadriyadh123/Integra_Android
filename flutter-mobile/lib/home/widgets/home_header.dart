import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final String studentName;
  final String className;
  final VoidCallback onNotificationTap;

  const HomeHeader({
    super.key,
    required this.studentName,
    required this.className,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF059669);
    const Color darkSlate = Color(0xFF0F172A);

    // Ambil inisial dari nama (maks 2 huruf)
    final parts = studentName.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : studentName.isNotEmpty
            ? studentName[0].toUpperCase()
            : '?';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Avatar inisial — tidak butuh URL gambar
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFECFDF5),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: primaryTeal,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selamat Datang,',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    studentName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: darkSlate,
                    ),
                  ),
                  if (className.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      className,
                      style: const TextStyle(
                        fontSize: 10,
                        color: primaryTeal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: onNotificationTap,
            icon: const Icon(Icons.notifications_outlined, color: darkSlate),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
