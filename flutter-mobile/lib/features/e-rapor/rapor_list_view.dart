import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/widgets/app_refresh_indicator.dart';
import 'package:provider/provider.dart';
import 'viewmodel/rapor_viewmodel.dart';
import 'models/rapor_model.dart';
import 'widgets/pdf_viewer_page.dart';
import '../widgets/shared_header.dart';

class RaporListViewPage extends StatefulWidget {
  final String authToken;

  const RaporListViewPage({super.key, required this.authToken});

  @override
  State<RaporListViewPage> createState() => _RaporListViewPageState();
}

class _RaporListViewPageState extends State<RaporListViewPage> {
  static const Color primaryTeal   = Color(0xFF059669);
  static const Color darkSlate     = Color(0xFF0F172A);
  static const Color backgroundSlate = Color(0xFFF8FAFC);
  static const Color textSlate     = Color(0xFF475569);
  static const Color borderSlate   = Color(0xFFE2E8F0);
  static const Color mutedSlate    = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<RaporViewModel>();
      if (!vm.isLoading && vm.reports.isEmpty && vm.errorMessage == null) {
        vm.fetchReportList(widget.authToken);
      }
    });
  }

  void _openPdf(BuildContext context, ReportCardHeader report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          raporId: report.id,
          title: 'E-Rapor ${report.semester}',
          authToken: widget.authToken,
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    final vm = context.read<RaporViewModel>();
    await vm.fetchReportList(widget.authToken);
    if (mounted && vm.lastSyncError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui: ${vm.lastSyncError}')),
      );
    }
  }

  // Warna aksen berdasarkan jenis rapor
  Color _accentColor(String reportType) {
    final t = reportType.toLowerCase();
    if (t.contains('akhir semester') || t.contains('sas')) {
      return const Color(0xFF0EA5E9); // biru — akhir semester
    }
    if (t.contains('akhir tahun') || t.contains('sat')) {
      return const Color(0xFF8B5CF6); // ungu — akhir tahun
    }
    return const Color(0xFFF59E0B); // amber — tengah semester (default)
  }

  String _shortReportType(String reportType) {
    final t = reportType.toLowerCase();
    if (t.contains('tengah')) return 'STS';
    if (t.contains('akhir semester')) return 'SAS';
    if (t.contains('akhir tahun')) return 'SAT';
    return reportType;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RaporViewModel>();

    return Scaffold(
      backgroundColor: backgroundSlate,
      appBar: SharedHeader(
        title: 'E-RAPOR DIKNAS',
        backgroundColor: Colors.white,
        foregroundColor: darkSlate,
        centerTitle: true,
        elevation: 0,
        showBackButton: true,
        onBack: () => Navigator.pop(context),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderSlate, height: 1),
        ),
      ),
      body: AppRefreshIndicator(
        color: primaryTeal,
        onRefresh: _onRefresh,
        child: vm.isLoading && vm.reports.isEmpty
            ? const Center(child: CircularProgressIndicator(color: primaryTeal))
            : vm.errorMessage != null
            ? _buildError(vm)
            : vm.reports.isEmpty
            ? _buildEmpty()
            : _buildList(vm),
      ),
    );
  }

  // ── Daftar ──────────────────────────────────────────────────────────────────

  Widget _buildList(RaporViewModel vm) {
    // Kelompokkan per tahun ajaran
    final Map<String, List<ReportCardHeader>> grouped = {};
    for (final r in vm.reports) {
      (grouped[r.academicYear] ??= []).add(r);
    }
    final years = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: years.length,
      itemBuilder: (context, i) {
        final year = years[i];
        final items = grouped[year]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header grup tahun ajaran
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 20, bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 13, color: primaryTeal),
                  const SizedBox(width: 6),
                  Text(
                    'Tahun Ajaran $year',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primaryTeal,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(height: 1, color: const Color(0xFFD1FAE5)),
                  ),
                ],
              ),
            ),
            // Item dalam grup
            ...items.asMap().entries.map((entry) {
              final idx = entry.key;
              final report = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: idx < items.length - 1 ? 10 : 0,
                ),
                child: _buildListTile(report),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildListTile(ReportCardHeader report) {
    final accent = _accentColor(report.reportType);
    final shortType = _shortReportType(report.reportType);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openPdf(context, report),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderSlate),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Aksen kiri + badge singkatan
                Container(
                  width: 56,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.08),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(13),
                      bottomLeft: Radius.circular(13),
                    ),
                    border: Border(left: BorderSide(color: accent, width: 4)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    shortType,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Konten utama
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Jenis rapor + semester
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                report.reportType,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: darkSlate,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _SemesterBadge(semester: report.semester),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Kelas
                        Row(
                          children: [
                            const Icon(Icons.class_rounded,
                                size: 12, color: mutedSlate),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                report.className,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: textSlate,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        // Rata-rata nilai (jika ada)
                        if (report.averageScore > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.bar_chart_rounded,
                                  size: 12, color: mutedSlate),
                              const SizedBox(width: 4),
                              Text(
                                'Rata-rata: ${report.averageScore.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: textSlate,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Chevron
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 20, color: mutedSlate),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Error & Empty ────────────────────────────────────────────────────────────

  Widget _buildError(RaporViewModel vm) {
    return SingleChildScrollView(
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
            const Icon(Icons.cloud_off_rounded, size: 52, color: mutedSlate),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Data',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: darkSlate,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              vm.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: textSlate),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tarik ke bawah untuk memuat ulang',
              style: TextStyle(fontSize: 11, color: mutedSlate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 52, color: mutedSlate),
            SizedBox(height: 16),
            Text(
              'Belum Ada E-Rapor',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: darkSlate,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'E-Rapor untuk semester ini belum tersedia.\nTarik ke bawah untuk memperbarui.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textSlate),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge semester ─────────────────────────────────────────────────────────────

class _SemesterBadge extends StatelessWidget {
  final String semester;
  const _SemesterBadge({required this.semester});

  @override
  Widget build(BuildContext context) {
    final isGasal = semester.toLowerCase().contains('gasal') ||
        semester.contains('1');
    final color = isGasal
        ? const Color(0xFF059669)
        : const Color(0xFF0EA5E9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        semester,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
