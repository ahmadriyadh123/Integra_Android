import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/widgets/app_refresh_indicator.dart';
import 'package:provider/provider.dart';
import '../../widgets/shared_header.dart';
import 'models/assignment_model.dart';
import 'viewmodel/assignment_viewmodel.dart';
import 'assignment_detail_view.dart';

class AssignmentListView extends StatefulWidget {
  final String authToken;

  const AssignmentListView({super.key, required this.authToken});

  @override
  State<AssignmentListView> createState() => _AssignmentListViewState();
}

class _AssignmentListViewState extends State<AssignmentListView> {
  static const Color primaryEmerald = Color(0xFF059669);
  static const Color bgSlate = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AssignmentViewModel>().fetchAssignments(widget.authToken);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSlate,
      appBar: SharedHeader(
        title: 'PENUGASAN',
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        elevation: 0,
        showBackButton: true,
        onBack: () => Navigator.pop(context),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Consumer<AssignmentViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading && vm.items.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: primaryEmerald),
            );
          }

          if (vm.errorMessage != null && vm.items.isEmpty) {
            return AppRefreshIndicator(
              color: primaryEmerald,
              onRefresh: () =>
                  vm.fetchAssignments(widget.authToken, forceRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.7,
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
                        'Gagal Memuat Penugasan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        vm.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final filtered = vm.filteredItems;

          return AppRefreshIndicator(
            color: primaryEmerald,
            onRefresh: () =>
                vm.fetchAssignments(widget.authToken, forceRefresh: true),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x05000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => vm.setSearchQuery(val),
                            decoration: InputDecoration(
                              hintText:
                                  'Cari nama tugas atau mata pelajaran...',
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF94A3B8),
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Color(0xFF94A3B8),
                                size: 20,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        vm.setSearchQuery('');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Filter Chips Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(
                                context,
                                label: 'Semua (${vm.items.length})',
                                filter: AssignmentFilter.all,
                                currentFilter: vm.currentFilter,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                context,
                                label: 'Perlu Dikumpulkan (${vm.pendingCount})',
                                filter: AssignmentFilter.pending,
                                currentFilter: vm.currentFilter,
                                badgeColor: const Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                context,
                                label:
                                    'Sudah Dikumpulkan (${vm.submittedCount})',
                                filter: AssignmentFilter.submitted,
                                currentFilter: vm.currentFilter,
                                badgeColor: const Color(0xFF0284C7),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                context,
                                label: 'Dinilai (${vm.gradedCount})',
                                filter: AssignmentFilter.graded,
                                currentFilter: vm.currentFilter,
                                badgeColor: primaryEmerald,
                              ),
                            ],
                          ),
                        ),
                        if (vm.isRefreshing) ...[
                          const SizedBox(height: 8),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  color: primaryEmerald,
                                  strokeWidth: 1.5,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Memperbarui data penugasan...',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: primaryEmerald,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Assignment List / Empty State
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.assignment_turned_in_outlined,
                              size: 56,
                              color: Color(0xFFCBD5E1),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              vm.searchQuery.isNotEmpty
                                  ? 'Tidak ada penugasan sesuai pencarian'
                                  : 'Belum Ada Penugasan',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              vm.searchQuery.isNotEmpty
                                  ? 'Coba gunakan kata kunci pencarian yang lain'
                                  : 'Penugasan dari guru akan muncul di sini',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildAssignmentCard(context, item),
                        );
                      }, childCount: filtered.length),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required AssignmentFilter filter,
    required AssignmentFilter currentFilter,
    Color? badgeColor,
  }) {
    final isSelected = filter == currentFilter;
    final color = badgeColor ?? primaryEmerald;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF475569),
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? color : const Color(0xFFE2E8F0)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onSelected: (_) {
        context.read<AssignmentViewModel>().setFilter(filter);
      },
    );
  }

  Widget _buildAssignmentCard(BuildContext context, AssignmentItem item) {
    final attachments = item.studentSubmission?.attachments ?? [];
    final status = _assignmentStatus(item);
    final startedAt = _formatDateTime(item.issuedDate);
    final deadline = _formatDateTime(item.submissionDeadline);
    final marks = item.studentSubmission?.marks;
    final gradeText = item.isGraded && marks != null
        ? '${marks.toStringAsFixed(marks.truncateToDouble() == marks ? 0 : 1)} / ${item.maxMarks.toStringAsFixed(0)}'
        : 'Belum dinilai';
    final uploadText = attachments.isEmpty
        ? (item.isSubmitted ? 'Terkumpul' : 'Belum ada berkas')
        : attachments.length == 1
        ? attachments.first.fileName
        : '${attachments.length} berkas diunggah';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssignmentDetailView(
              assignment: item,
              authToken: widget.authToken,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x080F172A),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: _buildSubjectPill(item.subject.name),
                        ),
                      ),
                      _buildStatusPill(status.$1, status.$2, status.$3),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      item.description.trim(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: textMuted,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateInfo(
                          icon: Icons.play_circle_outline_rounded,
                          label: 'Mulai',
                          value: startedAt.isEmpty ? '-' : startedAt,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateInfo(
                          icon: Icons.event_outlined,
                          label: 'Deadline',
                          value: deadline.isEmpty ? 'Tanpa batas' : deadline,
                          valueColor: item.isOverdue
                              ? const Color(0xFFDC2626)
                              : textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          attachments.isNotEmpty
                              ? Icons.attach_file_rounded
                              : Icons.upload_file_outlined,
                          size: 16,
                          color: attachments.isNotEmpty
                              ? primaryEmerald
                              : textMuted,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            uploadText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const SizedBox(
                          height: 20,
                          child: VerticalDivider(
                            width: 1,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          item.isGraded
                              ? Icons.grade_rounded
                              : Icons.workspace_premium_outlined,
                          size: 16,
                          color: item.isGraded ? primaryEmerald : textMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          gradeText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: item.isGraded ? primaryEmerald : textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectPill(String subject) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book_rounded, size: 13, color: primaryEmerald),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              subject,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: primaryEmerald,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String label, Color color, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDateInfo({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = textDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: valueColor,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  (String, Color, Color) _assignmentStatus(AssignmentItem item) {
    if (item.isGraded) {
      return ('Dinilai', const Color(0xFF047857), const Color(0xFFECFDF5));
    }
    if (item.isSubmitted) {
      return ('Terkumpul', const Color(0xFF0369A1), const Color(0xFFF0F9FF));
    }
    if (item.isOverdue) {
      return ('Terlambat', const Color(0xFFB91C1C), const Color(0xFFFEF2F2));
    }
    return (
      'Perlu dikumpulkan',
      const Color(0xFFB45309),
      const Color(0xFFFFFBEB),
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute';
  }
}
