import 'package:flutter/material.dart';
import 'document_reader_view.dart';
import 'quiz_view.dart';
import 'widgets/video/video_top_nav_bar.dart';
import 'widgets/video/video_player_section.dart';
import 'widgets/video/video_discussion_tab.dart';

class VideoPlayerView extends StatefulWidget {
  final String title;
  final String subject;
  final String teacher;

  const VideoPlayerView({
    super.key,
    this.title = '2. Aturan Sinus & Rumus',
    this.subject = 'Matematika Wajib',
    this.teacher = 'Bpk. Hendra, S.Pd',
  });

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> with SingleTickerProviderStateMixin {
  static const Color primaryColor = Color(0xFF059669);
  static const Color primaryLightColor = Color(0xFFECFDF5);
  static const Color darkBgColor = Color(0xFF0F172A);

  bool _isPlaying = true;
  bool _isBookmarked = false;
  double _currentSliderValue = 8.42;
  final double _totalDuration = 25.00;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToPdf() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentReaderView(
          title: 'Rangkuman_Aturan_Sinus.pdf',
          subject: widget.subject,
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
          subject: widget.subject,
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
      backgroundColor: darkBgColor,
      body: SafeArea(
        child: Column(
          children: [
            VideoTopNavBar(
              subject: widget.subject,
              title: widget.title,
              isBookmarked: _isBookmarked,
              onBackTap: () => Navigator.pop(context),
              onBookmarkTap: () {
                setState(() => _isBookmarked = !_isBookmarked);
                _showToast(_isBookmarked ? 'Materi disimpan ke favorit!' : 'Dihapus dari favorit');
              },
            ),
            VideoPlayerSection(
              isPlaying: _isPlaying,
              currentSliderValue: _currentSliderValue,
              totalDuration: _totalDuration,
              onPlayPauseTap: () {
                setState(() => _isPlaying = !_isPlaying);
                _showToast(_isPlaying ? 'Memutar Video' : 'Video Dijeda');
              },
              onSliderChanged: (value) => setState(() => _currentSliderValue = value),
              onActionTap: _showToast,
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    _buildVideoTitleHeader(),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDescriptionTab(),
                          _buildPlaylistTab(),
                          VideoDiscussionTab(onToastMessage: _showToast),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoTitleHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 14, color: primaryColor),
              const SizedBox(width: 4),
              Text(
                widget.teacher,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.visibility_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '124 Dilihat',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey.shade400,
        indicatorColor: primaryColor,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'Deskripsi & File'),
          Tab(text: 'Playlist Bab'),
          Tab(text: 'Diskusi (2)'),
        ],
      ),
    );
  }

  Widget _buildDescriptionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Materi',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pada video ini kita membahas mengenai konsep perbandingan panjang sisi segitiga sembarang dengan nilai sinus dari sudut di hadapannya.',
            style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.5),
          ),
          const SizedBox(height: 20),
          const Text(
            'Lampiran File Pembelajaran',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _navigateToPdf,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primaryLightColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rangkuman_Aturan_Sinus.pdf',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text('3.8 MB • Dokumen Bacaan PDF', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: primaryColor, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildPlaylistItem(
          number: '1',
          title: '1. Konsep Dasar Sudut',
          subtitle: '12 Menit • Video Selesai',
          icon: Icons.check,
          isCompleted: true,
          onTap: () => _showToast('Video selesai dipelajari'),
        ),
        const SizedBox(height: 12),
        _buildPlaylistItem(
          number: '2',
          title: '2. Aturan Sinus & Rumus',
          subtitle: '25 Menit • Sedang Diputar',
          icon: Icons.play_arrow_rounded,
          isActive: true,
          onTap: () => _showToast('Video ini sedang diputar'),
        ),
        const SizedBox(height: 12),
        _buildPlaylistItem(
          number: '3',
          title: '3. Handout & Rangkuman PDF',
          subtitle: '12 Halaman • Dokumen PDF',
          icon: Icons.picture_as_pdf_rounded,
          onTap: _navigateToPdf,
        ),
        const SizedBox(height: 12),
        _buildPlaylistItem(
          number: '4',
          title: '4. Kuis Akhir Bab 2',
          subtitle: 'Evaluasi • 5 Soal',
          icon: Icons.quiz_rounded,
          onTap: _navigateToQuiz,
        ),
      ],
    );
  }

  Widget _buildPlaylistItem({
    required String number,
    required String title,
    required String subtitle,
    required IconData icon,
    bool isCompleted = false,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? primaryLightColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? primaryColor : const Color(0xFFF1F5F9),
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isActive ? primaryColor : isCompleted ? primaryLightColor : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.white : isCompleted ? primaryColor : Colors.grey.shade600,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? primaryColor : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 10, color: isActive ? primaryColor : Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}