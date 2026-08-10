import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/elearning_model.dart';
import 'viewmodel/elearning_viewmodel.dart';
import 'widgets/detail/course_header_banner.dart';
import 'widgets/detail/teacher_info_card.dart';
import 'widgets/detail/curriculum_timeline_item.dart';

const Color _green = Color(0xFF059669);
const Color _bgSlate = Color(0xFFF8FAFC);
const Color _textDark = Color(0xFF1E293B);
const Color _textMuted = Color(0xFF94A3B8);

class DetailCourseView extends StatefulWidget {
  final int courseId;
  final String title;
  final String teacher;
  final String authToken;
  final IconData? iconData;
  final Color? iconBgColor;
  final Color? iconColor;

  const DetailCourseView({
    super.key,
    required this.courseId,
    required this.title,
    required this.teacher,
    required this.authToken,
    this.iconData,
    this.iconBgColor,
    this.iconColor,
  });

  @override
  State<DetailCourseView> createState() => _DetailCourseViewState();
}

class _DetailCourseViewState extends State<DetailCourseView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ElearningViewModel>();
      vm.fetchCourseDetail(widget.authToken, widget.courseId);
    });
  }

  @override
  void dispose() {
    // Bersihkan detail saat keluar agar fetch ulang saat masuk kursus lain
    context.read<ElearningViewModel>().clearDetail();
    super.dispose();
  }

  // Buka URL — untuk PDF gunakan browser, SCORM tidak punya URL langsung
  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) {
      _showSnack('Materi ini tidak tersedia secara langsung.');
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Tidak dapat membuka materi.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFA7F3D0), size: 18),
            const SizedBox(width: 10),
            Expanded(
                child: Text(msg, style: const TextStyle(fontSize: 12))),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Mapping tipe slide ke ikon & warna ──────────────────────────────────
  _SlideStyle _styleFor(String type) {
    switch (type) {
      case 'video':
        return _SlideStyle(
          icon: Icons.play_circle_rounded,
          iconBg: const Color(0xFFEFF6FF),
          iconColor: const Color(0xFF2563EB),
          badgeText: 'Video',
          badgeColor: const Color(0xFFDBEAFE),
        );
      case 'scorm':
        return _SlideStyle(
          icon: Icons.computer_rounded,
          iconBg: const Color(0xFFFFF7ED),
          iconColor: const Color(0xFFEA580C),
          badgeText: 'SCORM',
          badgeColor: const Color(0xFFFED7AA),
        );
      case 'quiz':
        return _SlideStyle(
          icon: Icons.quiz_rounded,
          iconBg: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFD97706),
          badgeText: 'Kuis',
          badgeColor: const Color(0xFFFEF3C7),
        );
      default: // document / pdf
        return _SlideStyle(
          icon: Icons.picture_as_pdf_rounded,
          iconBg: const Color(0xFFECFDF5),
          iconColor: _green,
          badgeText: 'PDF',
          badgeColor: const Color(0xFFD1FAE5),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgSlate,
      body: Consumer<ElearningViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoadingDetail) {
            return _buildLoading();
          }
          if (vm.detailError != null) {
            return _buildError(vm);
          }
          if (vm.courseDetail == null) {
            return _buildLoading();
          }
          return _buildContent(vm.courseDetail!);
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: _bgSlate,
      appBar: AppBar(
        backgroundColor: const Color(0xFF064E3B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
      body: const Center(child: CircularProgressIndicator(color: _green)),
    );
  }

  Widget _buildError(ElearningViewModel vm) {
    return Scaffold(
      backgroundColor: _bgSlate,
      appBar: AppBar(
        backgroundColor: const Color(0xFF064E3B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Coba Lagi',
            onPressed: () =>
                vm.fetchCourseDetail(widget.authToken, widget.courseId, forceRefresh: true),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 56, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 16),
              const Text('Gagal Memuat Detail',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textDark)),
              const SizedBox(height: 8),
              Text(vm.detailError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () =>
                    vm.fetchCourseDetail(widget.authToken, widget.courseId),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(CourseDetail detail) {
    final slides = detail.slides;
    final firstSlide = slides.isNotEmpty ? slides.first : null;

    return Consumer<ElearningViewModel>(
      builder: (context, vm, _) => Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CourseHeaderBanner(
                  title: detail.title,
                  onBackTap: () => Navigator.pop(context),
                  onPlayTap: () => _openUrl(firstSlide?.downloadUrl),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info guru
                      TeacherInfoCard(teacherName: detail.teacherName),

                      // Deskripsi (jika ada)
                      if (detail.description.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Text(
                            detail.description,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                                height: 1.5),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Header daftar materi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.import_contacts_rounded,
                                  size: 18, color: _green),
                              SizedBox(width: 8),
                              Text(
                                'Daftar Materi',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _textDark,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Badge "Memperbarui..." saat refresh background
                              if (vm.isRefreshingDetail) ...[
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
                                  style:
                                      TextStyle(fontSize: 10, color: _green),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                '${slides.length} Materi',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: _textMuted,
                                    fontWeight: FontWeight.w500),
                              ),
                              // Tombol force refresh cache
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => vm.clearDetailCache(
                                    widget.authToken, widget.courseId),
                                borderRadius: BorderRadius.circular(20),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.refresh_rounded,
                                      size: 16, color: _textMuted),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Timeline slide
                      if (slides.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text('Belum ada materi tersedia.',
                                style: TextStyle(color: _textMuted)),
                          ),
                        )
                      else
                        Stack(
                          children: [
                            Positioned(
                              left: 15,
                              top: 20,
                              bottom: 20,
                              child: Container(
                                  width: 2, color: Colors.grey.shade200),
                            ),
                            Column(
                              children: List.generate(slides.length, (i) {
                                final slide = slides[i];
                                final style = _styleFor(slide.materialType);
                                return Padding(
                                  padding: EdgeInsets.only(
                                      bottom: i < slides.length - 1 ? 16 : 0),
                                  child: CurriculumTimelineItem(
                                    stepNumber: '${i + 1}',
                                    title: '${i + 1}. ${slide.title}',
                                    subtitle: _subtitleFor(slide),
                                    icon: style.icon,
                                    iconBgColor: style.iconBg,
                                    iconTextColor: style.iconColor,
                                    badgeText: style.badgeText,
                                    badgeColor: style.badgeColor,
                                    onTap: () => _openUrl(slide.downloadUrl),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom CTA
          if (slides.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomCTA(firstSlide),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomCTA(SlideItem? firstSlide) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _openUrl(firstSlide?.downloadUrl),
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Mulai Belajar',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

// Helper class untuk styling slide
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
