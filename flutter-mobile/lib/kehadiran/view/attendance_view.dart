import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/attendance_viewmodel.dart';
import '../widgets/attendance_header.dart';
import '../widgets/attendance_heatmap_card.dart';
import '../widgets/attendance_list_card.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Consumer<AttendanceViewModel>(
          builder: (context, viewModel, _) {
            // 1. Handling State Loading
            if (viewModel.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0284C7),
                ),
              );
            }

            // 2. Handling State Error
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

            // 3. Handling Tampilan Data Berhasil Ditarik
            return RefreshIndicator(
              color: const Color(0xFF0284C7),
              onRefresh: () => viewModel.fetchAttendance(widget.authToken),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header dengan Dropdown Bulan & Tombol Back
                    AttendanceHeader(
                      showBackButton: Navigator.canPop(context),
                      activeMonthLabel: viewModel.activeMonthLabel,
                      availableMonths: viewModel.availableMonths,
                      onMonthChanged: viewModel.setActiveMonth,
                    ),
                    const SizedBox(height: 16),

                    // Heatmap Presensi Bulanan
                    AttendanceHeatmapCard(
                      totalDays: viewModel.filteredRecords.length,
                      heatmapCells: viewModel.generateHeatmapCells(),
                    ),
                    const SizedBox(height: 16),

                    // Daftar Riwayat Presensi Mingguan
                    if (viewModel.filteredRecords.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: Text(
                            'Belum ada data presensi pada bulan ini.',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    else
                      AttendanceListCard(
                        sortedWeekStarts: viewModel.sortedWeekStarts,
                        groupedWeeks: viewModel.groupedWeeks,
                        getMonthName: viewModel.getMonthName,
                        getWeekdayName: viewModel.getWeekdayName,
                        activeMonthLabel: viewModel.activeMonthLabel,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}