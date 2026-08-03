import 'package:flutter/material.dart';

class QuizTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String subject;
  final String title;
  final bool isSubmitted;
  final VoidCallback onExitTap;

  const QuizTopBar({
    super.key,
    required this.subject,
    required this.title,
    required this.isSubmitted,
    required this.onExitTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color darkBgColor = Color(0xFF0F172A);

    return AppBar(
      backgroundColor: darkBgColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
        onPressed: onExitTap,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFA7F3D0),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        if (!isSubmitted)
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: const Row(
              children: [
                Icon(Icons.timer_outlined, color: Color(0xFFA7F3D0), size: 14),
                SizedBox(width: 4),
                Text(
                  '14:25',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}