import 'package:flutter/material.dart';

import '../../../../data/model/elearning/elearning_model.dart';
import './curriculum_timeline_item.dart';

class CourseMaterialTimeline extends StatelessWidget {
  final List<SlideItem> slides;
  final Set<int> offlineSlideIds;
  final Set<int> downloadingSlideIds;
  final bool isRefreshing;
  final ValueChanged<SlideItem> onOpenSlide;
  final ValueChanged<SlideItem> onToggleOffline;

  const CourseMaterialTimeline({
    super.key,
    required this.slides,
    required this.offlineSlideIds,
    required this.downloadingSlideIds,
    required this.isRefreshing,
    required this.onOpenSlide,
    required this.onToggleOffline,
  });

  static const _green = Color(0xFF059669);
  static const _muted = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.import_contacts_rounded, size: 18, color: _green),
              SizedBox(width: 8),
              Text(
                'Daftar Materi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (isRefreshing) ...[
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    color: _green,
                    strokeWidth: 1.5,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Memperbarui...',
                  style: TextStyle(fontSize: 10, color: _green),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                '${slides.length} Materi',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 16),
      if (slides.isEmpty)
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Belum ada materi tersedia.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
        )
      else
        Stack(
          children: [
            Positioned(
              left: 15,
              top: 20,
              bottom: 20,
              child: Container(width: 2, color: Colors.grey.shade200),
            ),
            Column(
              children: List.generate(slides.length, (index) {
                final slide = slides[index];
                final style = _styleFor(slide.materialType);
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < slides.length - 1 ? 16 : 0,
                  ),
                  child: CurriculumTimelineItem(
                    stepNumber: '${index + 1}',
                    title: '${index + 1}. ${slide.title}',
                    subtitle: _subtitleFor(slide),
                    icon: style.icon,
                    iconBgColor: style.iconBg,
                    iconTextColor: style.iconColor,
                    badgeText: style.badgeText,
                    badgeColor: style.badgeColor,
                    isCompleted: slide.isCompleted,
                    onTap: () => onOpenSlide(slide),
                    trailing: _buildTrailing(slide),
                  ),
                );
              }),
            ),
          ],
        ),
    ],
  );

  Widget _buildTrailing(SlideItem slide) {
    if (slide.isQuiz) {
      return const Tooltip(
        message: 'Kuis offline belum tersedia',
        child: Icon(Icons.cloud_outlined, size: 18, color: _muted),
      );
    }
    if (downloadingSlideIds.contains(slide.id)) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2, color: _green),
      );
    }
    final isOffline = offlineSlideIds.contains(slide.id);
    return IconButton(
      tooltip: isOffline ? 'Hapus dari offline' : 'Simpan offline',
      visualDensity: VisualDensity.compact,
      onPressed: () => onToggleOffline(slide),
      icon: Icon(
        isOffline
            ? Icons.offline_pin_rounded
            : Icons.download_for_offline_outlined,
        color: _green,
        size: 21,
      ),
    );
  }

  _SlideStyle _styleFor(String type) {
    switch (type) {
      case 'video':
        return const _SlideStyle(
          icon: Icons.play_circle_rounded,
          iconBg: Color(0xFFEFF6FF),
          iconColor: Color(0xFF2563EB),
          badgeText: 'Video',
          badgeColor: Color(0xFFDBEAFE),
        );
      case 'scorm':
        return const _SlideStyle(
          icon: Icons.computer_rounded,
          iconBg: Color(0xFFFFF7ED),
          iconColor: Color(0xFFEA580C),
          badgeText: 'SCORM',
          badgeColor: Color(0xFFFED7AA),
        );
      case 'quiz':
        return const _SlideStyle(
          icon: Icons.quiz_rounded,
          iconBg: Color(0xFFFEF3C7),
          iconColor: Color(0xFFD97706),
          badgeText: 'Kuis',
          badgeColor: Color(0xFFFEF3C7),
        );
      default:
        return const _SlideStyle(
          icon: Icons.picture_as_pdf_rounded,
          iconBg: Color(0xFFECFDF5),
          iconColor: _green,
          badgeText: 'PDF',
          badgeColor: Color(0xFFD1FAE5),
        );
    }
  }

  String _subtitleFor(SlideItem slide) {
    switch (slide.materialType) {
      case 'video':
        return 'Video Pembelajaran';
      case 'scorm':
        return 'Modul Interaktif SCORM';
      case 'quiz':
        return 'Evaluasi / Kuis';
      default:
        return 'Dokumen PDF';
    }
  }
}

class _SlideStyle {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String badgeText;
  final Color badgeColor;

  const _SlideStyle({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.badgeText,
    required this.badgeColor,
  });
}
