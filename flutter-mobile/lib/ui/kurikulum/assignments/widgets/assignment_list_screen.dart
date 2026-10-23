import 'package:flutter/material.dart';
import 'package:flutter_application_1/ui/core/ui/app_refresh_indicator.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/shared_header.dart';
import '../../../../data/model/kurikulum/assignments/assignment_model.dart';
import '../view_models/assignment_viewmodel.dart';
import './assignment_detail_screen.dart';
import './assignment_card.dart';

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
    return AssignmentCard(
      item: item,
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
    );
  }
}
