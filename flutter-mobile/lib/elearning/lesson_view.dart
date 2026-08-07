import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/elearning_model.dart';
import 'viewmodel/elearning_viewmodel.dart';
import 'detail_course_view.dart';
import 'widgets/elearning_header.dart';
import 'widgets/subject_grid_card.dart';

// Tetap dipertahankan agar import lama tidak error, tapi tidak dipakai lagi
class ElearningApp extends StatelessWidget {
  const ElearningApp({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ── Palette ──────────────────────────────────────────────────────────────────
const Color _green = Color(0xFF059669);
const Color _bgSlate = Color(0xFFF8FAFC);
const Color _textDark = Color(0xFF1E293B);
const Color _textMuted = Color(0xFF94A3B8);
const Color _borderColor = Color(0xFFF1F5F9);

// Warna ikon per urutan channel (cycling)
const List<_CourseColor> _courseColors = [
  _CourseColor(Color(0xFFEFF6FF), Color(0xFF2563EB), Icons.functions),
  _CourseColor(Color(0xFFFFF1F2), Color(0xFFE11D48), Icons.science),
  _CourseColor(Color(0xFFECFDF5), Color(0xFF059669), Icons.eco_outlined),
  _CourseColor(Color(0xFFFFF7ED), Color(0xFFEA580C), Icons.public),
  _CourseColor(Color(0xFFF0FDFA), Color(0xFF0D9488), Icons.translate),
  _CourseColor(Color(0xFFF0F9FF), Color(0xFF0284C7), Icons.computer),
  _CourseColor(Color(0xFFFDF4FF), Color(0xFF9333EA), Icons.music_note),
  _CourseColor(Color(0xFFFFFBEB), Color(0xFFD97706), Icons.brush),
];

class _CourseColor {
  final Color bg;
  final Color icon;
  final IconData iconData;
  const _CourseColor(this.bg, this.icon, this.iconData);
}

// ── Main View ─────────────────────────────────────────────────────────────────
class PelajaranView extends StatefulWidget {
  final String authToken;
  const PelajaranView({super.key, required this.authToken});

  @override
  State<PelajaranView> createState() => _PelajaranViewState();
}

class _PelajaranViewState extends State<PelajaranView> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ElearningViewModel>();
      if (!vm.isLoadingCourses && !vm.hasCourses && vm.coursesError == null) {
        vm.fetchCourses(widget.authToken);
      }
    });
  }

  List<CourseItem> _filtered(List<CourseItem> courses) {
    if (_searchQuery.isEmpty) return courses;
    final q = _searchQuery.toLowerCase();
    return courses
        .where((c) =>
            c.title.toLowerCase().contains(q) ||
            c.teacherName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgSlate,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: ElearningHeader(
          onSearchChanged: (val) => setState(() => _searchQuery = val),
        ),
        actions: [
          Consumer<ElearningViewModel>(
            builder: (context, vm, _) => PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: Color(0xFF475569)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'refresh') {
                  vm.fetchCourses(widget.authToken, forceRefresh: true);
                } else if (val == 'clear') {
                  vm.clearAllCache(widget.authToken);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh_rounded,
                          size: 18, color: Color(0xFF475569)),
                      SizedBox(width: 10),
                      Text('Perbarui dari Server',
                          style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_rounded,
                          size: 18, color: Color(0xFFEF4444)),
                      SizedBox(width: 10),
                      Text('Hapus Cache',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFFEF4444))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<ElearningViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoadingCourses) {
            return const Center(
              child: CircularProgressIndicator(color: _green),
            );
          }
          if (vm.coursesError != null) {
            return _buildError(vm);
          }
          if (!vm.hasCourses) {
            return _buildEmpty();
          }
          return _buildCourseList(vm);
        },
      ),
    );
  }

  Widget _buildCourseList(ElearningViewModel vm) {
    final filtered = _filtered(vm.courses);

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada hasil untuk "$_searchQuery"',
          style: const TextStyle(color: _textMuted, fontSize: 13),
        ),
      );
    }

    return RefreshIndicator(
      color: _green,
      onRefresh: () => vm.fetchCourses(widget.authToken, forceRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header jumlah mapel
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.grid_view_rounded, size: 18, color: _green),
                    SizedBox(width: 8),
                    Text(
                      'Semua Mata Pelajaran',
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
                    if (vm.isRefreshingCourses) ...[
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
                      'Total ${filtered.length} Mapel',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Grid kursus
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.88,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final course = filtered[i];
                final colors = _courseColors[i % _courseColors.length];
                return SubjectGridCard(
                  title: course.title,
                  chapterCount: '${course.totalSlides} Materi',
                  icon: colors.iconData,
                  iconBgColor: colors.bg,
                  iconColor: colors.icon,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailCourseView(
                        courseId: course.id,
                        title: course.title,
                        teacher: course.teacherName,
                        authToken: widget.authToken,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ElearningViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Data',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: _textDark),
            ),
            const SizedBox(height: 8),
            Text(
              vm.coursesError!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => vm.fetchCourses(widget.authToken),
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
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, size: 56, color: Color(0xFFCBD5E1)),
            SizedBox(height: 16),
            Text(
              'Belum Ada Kursus',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: _textDark),
            ),
            SizedBox(height: 8),
            Text(
              'Belum ada mata pelajaran yang dipublikasikan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
          ],
        ),
      ),
    );
  }
}
