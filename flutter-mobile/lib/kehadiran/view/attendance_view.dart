import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/attendance_viewmodel.dart';
import '../widgets/attendance_header.dart';
import '../widgets/attendance_heatmap_card.dart';
import '../widgets/attendance_list_card.dart';
import '../widgets/attendance_summary_section.dart';

class AttendanceView extends StatefulWidget {
  final String authToken;

  const AttendanceView({
    super.key,
    required this.authToken,
  });

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<AttendanceViewModel>();
      vm.fetchAttendance(widget.authToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Consumer<AttendanceViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0284C7),
                ),
              );
            }

            if (viewModel.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        viewModel.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () =>
                            viewModel.fetchAttendance(widget.authToken),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: const Color(0xFF0284C7),
              onRefresh: () => viewModel.fetchAttendance(widget.authToken),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header & Selector
                    AttendanceHeader(
                      showBackButton: Navigator.canPop(context),
                      activeMonthLabel: viewModel.activeMonthLabel,
                      availableMonths: viewModel.availableMonths,
                      onMonthChanged: viewModel.setActiveMonth,
                    ),
                    const SizedBox(height: 20),

                    // 2. Summary Section
                    AttendanceSummarySection(
                      totalPresent: viewModel.totalPresent,
                      totalSick: viewModel.totalSick,
                      totalPermit: viewModel.totalPermit,
                      totalAlpha: viewModel.totalAlpha,
                      percentage: viewModel.attendancePercentage,
                    ),
                    const SizedBox(height: 24),

                    // 3. Heatmap Visual
                    const Text(
                      'KALENDER PRESENSI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AttendanceHeatmapCard(
                      totalDays: viewModel.filteredRecords.length,
                      heatmapCells: viewModel.generateHeatmapCells(),
                    ),
                    const SizedBox(height: 24),

                    // 4. Detailed History
                    const Text(
                      'RIWAYAT DETAIL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (viewModel.filteredRecords.isEmpty)
                      _buildEmptyState()
                    else
                      AttendanceListCard(
                        sortedWeekStarts: viewModel.sortedWeekStarts,
                        groupedWeeks: viewModel.groupedWeeks,
                        getMonthName: viewModel.getMonthName,
                        getWeekdayName: viewModel.getWeekdayName,
                        activeMonthLabel: viewModel.activeMonthLabel,
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_busy_rounded, size: 48, color: Color(0xFFCBD5E1)),
          SizedBox(height: 12),
          Text(
            'Belum ada data presensi.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
