import 'package:flutter/material.dart';

class DocumentTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subject;
  final VoidCallback onBackTap;
  final VoidCallback onDownloadTap;

  const DocumentTopBar({
    super.key,
    required this.title,
    required this.subject,
    required this.onBackTap,
    required this.onDownloadTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color darkBgColor = Color(0xFF0F172A);
    const Color primaryLight = Color(0xFFA7F3D0);

    return AppBar(
      backgroundColor: darkBgColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        onPressed: onBackTap,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject.toUpperCase(),
            style: const TextStyle(
              color: primaryLight,
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
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: onDownloadTap,
          icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
          tooltip: 'Unduh Dokumen',
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}