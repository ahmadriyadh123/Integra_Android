import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/elearning_model.dart';
import 'viewmodel/elearning_viewmodel.dart';
import 'detail_course_view.dart';
import 'widgets/elearning_header.dart';
import 'widgets/subject_grid_card.dart';
import 'widgets/active_course_card.dart';

// Tetap dipertahankan agar import lama tidak error
class ElearningApp extends StatelessWidget {
  const ElearningApp({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

const Color _green = Color(0xFF059669);
const Color _bgSlate = Color(0xFFF8FAFC);
const Color _textDark = Color(0xFF1E293B);
const Color _textMuted = Color(0xFF94A3B8);

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
        .where(
          (c) =>
              c.title.toLowerCase().contains(q) ||
              c.teacherName.toLowerCase().contains(q),
        )
        .toList();
  }

  void _navigateToDetail(BuildContext context, CourseItem course, int index) {
    final colors = _courseColors[index % _courseColors.length];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailCourseView(
          courseId: course.id,
          title: course.title,
          teacher: course.teacherName,
          authToken: widget.authToken,
          iconData: colors.iconData,
          iconBgColor: colors.bg,
          iconColor: colors.icon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgSlate,
      body: Column(
        children: [
          // Header dengan search — tidak pakai AppBar agar header tetap full-width
          ElearningHeader(
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            onClearCacheTap: () {
              final vm = context.read<ElearningViewModel>();
              vm.clearAllCache(widget.authToken);
            },
          ),
          Expanded(
            child: Consumer<ElearningViewModel>(
              builder: (context, vm, _) {
                if (vm.isLoadingCourses && !vm.hasCourses) {
                  return const Center(
                    child: CircularProgressIndicator(color: _green),
                  );
                }
                return RefreshIndicator(
                  color: _green,
                  onRefresh: () => vm.fetchCourses(widget.authToken, forceRefresh: true),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: vm.coursesError != null
                        ? _buildError(vm)
                        : !vm.hasCourses
                            ? _buildEmpty()
                            : _buildBodyContent(vm),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(ElearningViewModel vm) {
    final filtered = _filtered(vm.courses);

    if (filtered.isEmpty) {
      return Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        alignment: Alignment.center,
        child: Text(
          'Tidak ada hasil untuk "$_searchQuery"',
          style: const TextStyle(color: _textMuted, fontSize: 13),
        ),
      );
    }

    // Kursus pertama sebagai "Sedang Dipelajari"
    final activeCourse = vm.courses.first;
    final activeColors = _courseColors[0];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_searchQuery.isEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(
                  icon: Icons.play_circle_rounded,
                  title: 'Sedang Dipelajari',
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Aktif',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ActiveCourseCard(
              title: activeCourse.title,
              teacher: activeCourse.teacherName.isNotEmpty
                  ? activeCourse.teacherName
                  : 'Guru Pengampu',
              progress: 0.65,
              icon: activeColors.iconData,
              iconBgColor: activeColors.bg,
              iconColor: activeColors.icon,
              onTap: () => _navigateToDetail(context, activeCourse, 0),
            ),
            const SizedBox(height: 28),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(
                icon: Icons.grid_view_rounded,
                title: 'Daftar Mata Pelajaran',
              ),
              Row(
                children: [
                  // Badge "Memperbarui..." saat background refresh
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
                    '${filtered.length} Mapel',
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
                onTap: () => _navigateToDetail(context, course, i),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? badge,
    Color badgeBg = const Color(0xFFECFDF5),
    Color badgeColor = _green,
  }) {
    return Row(
      children: [
        Icon(icon, size: 17, color: _green),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _textDark,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildError(ElearningViewModel vm) {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 56,
            color: Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 16),
          const Text(
            'Gagal Memuat Data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_rounded, size: 56, color: Color(0xFFCBD5E1)),
          SizedBox(height: 16),
          Text(
            'Belum Ada Kursus',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Belum ada mata pelajaran yang dipublikasikan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
}
