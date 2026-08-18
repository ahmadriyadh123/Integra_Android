import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/weekly_plan_model.dart';
import 'viewmodel/weekly_plan_viewmodel.dart';
import 'weekly_plan_detail_view.dart';
import '../../widgets/shared_header.dart';

class WeeklyPlanScreen extends StatefulWidget {
  final String authToken;

  const WeeklyPlanScreen({super.key, required this.authToken});

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  static const Color primaryTeal  = Color(0xFF059669);
  static const Color darkSlate    = Color(0xFF0F172A);
  static const Color bgSlate      = Color(0xFFF8FAFC);
  static const Color textSlate    = Color(0xFF475569);
  static const Color textMuted    = Color(0xFF94A3B8);
  static const Color borderColor  = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<WeeklyPlanViewModel>();
      if (!vm.isLoading && !vm.hasData && vm.errorMessage == null) {
        vm.fetchList(widget.authToken);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSlate,
      appBar: SharedHeader(
        title: 'WEEKLY PLAN',
        backgroundColor: Colors.white,
        foregroundColor: darkSlate,
        centerTitle: true,
        elevation: 0,
        showBackButton: true,
        onBack: () => Navigator.pop(context),
        actions: [
          Consumer<WeeklyPlanViewModel>(
            builder: (_, vm, __) => IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: primaryTeal, size: 22),
              onPressed: vm.isLoading
                  ? null
                  : () => vm.fetchList(widget.authToken),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: Consumer<WeeklyPlanViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: primaryTeal));
          }
          if (vm.errorMessage != null) return _buildError(vm);
          if (!vm.hasData) return _buildEmpty();
          return _buildList(vm);
        },
      ),
    );
  }

  Widget _buildList(WeeklyPlanViewModel vm) {
    return RefreshIndicator(
      color: primaryTeal,
      onRefresh: () => vm.fetchList(widget.authToken),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: vm.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _buildCard(vm.items[i], vm),
      ),
    );
  }

  Widget _buildCard(WeeklyPlanItem item, WeeklyPlanViewModel vm) {
    final statusColor = item.isSubmitted
        ? const Color(0xFF059669)
        : const Color(0xFF94A3B8);
    final statusLabel = item.status == 'approved'
        ? 'Disetujui'
        : item.status == 'submitted'
            ? 'Diajukan'
            : 'Draft';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: primaryTeal, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris atas: tahun ajaran + status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.school_rounded,
                          size: 14, color: primaryTeal),
                      const SizedBox(width: 5),
                      Text(
                        item.tahunAjaran,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primaryTeal,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Kelas
              Text(
                item.kelas,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: darkSlate,
                ),
              ),
              const SizedBox(height: 4),

              // Semester & Pekan
              Row(
                children: [
                  const Icon(Icons.date_range_rounded,
                      size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    '${item.semester}  •  Pekan: ${item.pekan}',
                    style: const TextStyle(
                        fontSize: 12, color: textSlate),
                  ),
                ],
              ),

              // Tema (jika ada)
              if (item.tema.isNotEmpty && item.tema != '-') ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.bookmark_outline_rounded,
                        size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.tema,
                        style: const TextStyle(
                            fontSize: 12, color: textSlate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),
              const Divider(height: 1, color: borderColor),
              const SizedBox(height: 12),

              // Tombol lihat PDF
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WeeklyPlanDetailScreen(
                        planId: item.id,
                        title:
                            '${item.kelas} — Pekan ${item.pekan}',
                        authToken: widget.authToken,
                      ),
                    ),
                  ),
                  icon: const Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 16),
                  label: const Text(
                    'Lihat Weekly Plan',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryTeal,
                    side: const BorderSide(color: primaryTeal),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(WeeklyPlanViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text('Gagal Memuat Data',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: darkSlate)),
            const SizedBox(height: 8),
            Text(vm.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: textSlate)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => vm.fetchList(widget.authToken),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
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
            Icon(Icons.description_outlined,
                size: 56, color: Color(0xFFCBD5E1)),
            SizedBox(height: 16),
            Text('Belum Ada Weekly Plan',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: darkSlate)),
            SizedBox(height: 8),
            Text(
              'Weekly Plan untuk kelas Anda belum tersedia.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textSlate),
            ),
          ],
        ),
      ),
    );
  }
}
