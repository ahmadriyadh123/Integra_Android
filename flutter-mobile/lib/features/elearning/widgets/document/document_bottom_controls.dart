import 'package:flutter/material.dart';

class DocumentBottomControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPreviousTap;
  final VoidCallback onNextTap;
  final VoidCallback onZoomInTap;
  final VoidCallback onZoomOutTap;

  const DocumentBottomControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPreviousTap,
    required this.onNextTap,
    required this.onZoomInTap,
    required this.onZoomOutTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF059669);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: currentPage > 1 ? onPreviousTap : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: primaryColor,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    disabledBackgroundColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$currentPage / $totalPages',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: currentPage < totalPages ? onNextTap : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: primaryColor,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    disabledBackgroundColor: const Color(0xFFF8FAFC),
                  ),
                ),
              ],
            ),
            
            // Kontrol Zoom
            Row(
              children: [
                IconButton(
                  onPressed: onZoomOutTap,
                  icon: const Icon(Icons.zoom_out_rounded, size: 20),
                  color: const Color(0xFF475569),
                ),
                IconButton(
                  onPressed: onZoomInTap,
                  icon: const Icon(Icons.zoom_in_rounded, size: 20),
                  color: const Color(0xFF475569),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}