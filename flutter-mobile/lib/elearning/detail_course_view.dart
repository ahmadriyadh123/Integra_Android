import 'package:flutter/material.dart';
import 'video_player_view.dart';
import 'document_reader_view.dart';
import 'quiz_view.dart';
import 'widgets/detail/course_header_banner.dart';
import 'widgets/detail/teacher_info_card.dart';
import 'widgets/detail/curriculum_timeline_item.dart';

class DetailCourseView extends StatefulWidget {
  final String title;
  final String teacher;

  const DetailCourseView({
    super.key,
    this.title = 'Matematika Wajib',
    this.teacher = 'Bpk. Hendra, S.Pd',
  });

  @override
  State<DetailCourseView> createState() => _DetailCourseViewState();
}

class _DetailCourseViewState extends State<DetailCourseView> {
  static const Color primaryColor = Color(0xFF059669);
  static const Color backgroundColor = Color(0xFFF8FAFC);

  void _navigateToVideo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerView(
          title: '2. Aturan Sinus & Rumus',
          subject: widget.title,
          teacher: widget.teacher,
        ),
      ),
    );
  }

  void _navigateToPdf() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentReaderView(
          title: 'Rangkuman_Aturan_Sinus.pdf',
          subject: widget.title,
        ),
      ),
    );
  }

  void _navigateToQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizView(
          title: 'Kuis Akhir Bab 2: Aturan Sinus & Cosinus',
          subject: widget.title,
        ),
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFFA7F3D0), size: 18),
            const SizedBox(width: 10),
            Text(message, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CourseHeaderBanner(
                  title: widget.title,
                  onBackTap: () => Navigator.pop(context),
                  onPlayTap: _navigateToVideo,
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TeacherInfoCard(teacherName: widget.teacher),
                      const SizedBox(height: 24),
                      
                      Row(
                        children: const [
                          Icon(Icons.import_contacts_rounded, size: 18, color: primaryColor),
                          SizedBox(width: 8),
                          Text(
                            'Kurikulum & Modul Pembelajaran',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Curriculum Timeline
                      Stack(
                        children: [
                          Positioned(
                            left: 15,
                            top: 20,
                            bottom: 20,
                            child: Container(
                              width: 2,
                              color: Colors.grey.shade200,
                            ),
                          ),
                          Positioned(
                            left: 15,
                            top: 20,
                            height: 160,
                            child: Container(
                              width: 2,
                              color: primaryColor,
                            ),
                          ),
                          Column(
                            children: [
                              CurriculumTimelineItem(
                                stepNumber: '1',
                                title: '1. Konsep Dasar Sudut',
                                subtitle: 'Video Pembelajaran • 12 Menit',
                                icon: Icons.check,
                                iconBgColor: primaryColor,
                                iconTextColor: Colors.white,
                                isCompleted: true,
                                onTap: _navigateToVideo,
                              ),
                              const SizedBox(height: 16),
                              CurriculumTimelineItem(
                                stepNumber: '2',
                                title: '2. Aturan Sinus & Rumus',
                                subtitle: 'Video Pembelajaran • 25 Menit',
                                icon: Icons.play_arrow_rounded,
                                iconBgColor: Colors.white,
                                iconTextColor: primaryColor,
                                isActive: true,
                                badgeText: 'Sedang Diputar',
                                onTap: _navigateToVideo,
                              ),
                              const SizedBox(height: 16),
                              CurriculumTimelineItem(
                                stepNumber: '3',
                                title: '3. Handout & Rangkuman PDF',
                                subtitle: 'Dokumen Bacaan • 12 Halaman',
                                icon: Icons.picture_as_pdf_rounded,
                                iconBgColor: const Color(0xFFECFDF5),
                                iconTextColor: primaryColor,
                                badgeText: 'Dokumen PDF',
                                badgeColor: const Color(0xFFD1FAE5),
                                onTap: _navigateToPdf,
                              ),
                              const SizedBox(height: 16),
                              CurriculumTimelineItem(
                                stepNumber: '4',
                                title: '4. Slide Presentasi Guru',
                                subtitle: 'Dokumen PPTX • 24 Slide',
                                icon: Icons.check,
                                iconBgColor: primaryColor,
                                iconTextColor: Colors.white,
                                isCompleted: true,
                                onTap: () => _showToast('Materi presentasi sudah selesai dibaca'),
                              ),
                              const SizedBox(height: 16),
                              CurriculumTimelineItem(
                                stepNumber: '5',
                                title: '5. Kuis Akhir Bab 2',
                                subtitle: 'Evaluasi Pilihan Ganda • 5 Soal',
                                icon: Icons.quiz_rounded,
                                iconBgColor: const Color(0xFFFEF3C7),
                                iconTextColor: const Color(0xFFD97706),
                                badgeText: 'Wajib Dikerjakan',
                                badgeColor: const Color(0xFFFEF3C7),
                                onTap: _navigateToQuiz,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 80), // Padding untuk Bottom CTA
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomCTA(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCTA(BuildContext context) {
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
        onPressed: _navigateToVideo,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Lanjutkan Belajar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}