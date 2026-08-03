import 'package:flutter/material.dart';

class VideoTopNavBar extends StatelessWidget {
  final String subject;
  final String title;
  final bool isBookmarked;
  final VoidCallback onBackTap;
  final VoidCallback onBookmarkTap;

  const VideoTopNavBar({
    super.key,
    required this.subject,
    required this.title,
    required this.isBookmarked,
    required this.onBackTap,
    required this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color secondaryColor = Color(0xFFF59E0B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onBackTap,
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(8),
            ),
          ),
          Column(
            children: [
              Text(
                subject.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFA7F3D0),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: onBookmarkTap,
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? secondaryColor : Colors.white,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
}