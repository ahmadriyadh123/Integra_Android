import 'package:flutter/material.dart';

class CourseHeaderBanner extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int? durasiMenit;
  final VoidCallback onBackTap;
  final VoidCallback? onPlayTap;
  final bool showPlayButton;

  const CourseHeaderBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.durasiMenit,
    required this.onBackTap,
    this.onPlayTap,
    this.showPlayButton = true,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF059669);
    const Color secondaryColor = Color(0xFFF59E0B);

    final String displayDurasi = durasiMenit != null
        ? '$durasiMenit Materi'
        : '';

    return Container(
      height: 280,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF064E3B),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 48,
            left: 20,
            child: InkWell(
              onTap: onBackTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
            ),
          ),
          if (showPlayButton && onPlayTap != null)
            Center(
              child: Material(
                color: Colors.white.withValues(alpha: 0.3),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onPlayTap,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: primaryColor, size: 32),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: secondaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'E-Learning',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (displayDurasi.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(Icons.layers_outlined,
                              color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            displayDurasi,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}