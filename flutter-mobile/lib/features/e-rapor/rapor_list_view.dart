import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodel/rapor_viewmodel.dart';
import 'models/rapor_model.dart';
import 'widgets/pdf_viewer_page.dart';
import '../widgets/shared_header.dart';

class RaporListViewPage extends StatefulWidget {
  final String authToken;

  const RaporListViewPage({
    super.key,
    required this.authToken,
  });

  @override
  State<RaporListViewPage> createState() => _RaporListViewPageState();
}

class _RaporListViewPageState extends State<RaporListViewPage> {
  static const Color primaryTeal     = Color(0xFF059669);
  static const Color deepTeal        = Color(0xFF064E3B);
  static const Color warmAmber       = Color(0xFFF59E0B);
  static const Color darkSlate       = Color(0xFF0F172A);
  static const Color backgroundSlate = Color(0xFFF8FAFC);
  static const Color textSlate       = Color(0xFF475569);
  static const Color borderSlate     = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<RaporViewModel>();
      // Cukup panggil tanpa forceRefresh agar membaca cache Hive terlebih dahulu
      if (!vm.isLoading && vm.reports.isEmpty && vm.errorMessage == null) {
        vm.fetchReportList(widget.authToken);
      }
    });
  }

  void _openPdf(BuildContext context, ReportCardHeader report) {
    final vm = context.read<RaporViewModel>();
    final pdfUrl = vm.getPdfUrl(report.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          pdfUrl: pdfUrl,
          title: 'E-Rapor ${report.semester}',
          authToken: widget.authToken,
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    await context.read<RaporViewModel>().fetchReportList(
          widget.authToken,
          forceRefresh: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RaporViewModel>();

    return Scaffold(
      backgroundColor: backgroundSlate,
      appBar: SharedHeader(
        title: 'E-RAPOR',
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
      body: RefreshIndicator(
        color: primaryTeal,
        onRefresh: _onRefresh,
        child: vm.isLoading && vm.reports.isEmpty
            ? const Center(child: CircularProgressIndicator(color: primaryTeal))
            : vm.errorMessage != null
                ? _buildError(vm)
                : vm.reports.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: vm.reports.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, i) => i == 0
                            ? _buildIntro(vm.reports.length)
                            : _buildCard(context, vm.reports[i - 1]),
                      ),
      ),
    );
  }

  Widget _buildIntro(int reportCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [deepTeal, Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: deepTeal.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rapor Perkembangan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$reportCount laporan akademik tersedia',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.insights_rounded, color: Color(0xFFFDE68A), size: 24),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, ReportCardHeader report) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD1FAE5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1006473B),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: warmAmber, width: 5)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 17, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.school_rounded, size: 14, color: primaryTeal),
                      const SizedBox(width: 5),
                      Text(
                        report.academicYear,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: deepTeal,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Rata-rata: ${report.averageScore.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                report.semester,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: darkSlate,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.class_outlined, size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    report.className,
                    style: const TextStyle(fontSize: 12, color: textSlate),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: borderSlate),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openPdf(context, report),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                  label: const Text(
                    'Lihat E-Rapor PDF',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: deepTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            const Icon(Icons.cloud_off_rounded, size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: darkSlate),
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
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
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
            Icon(Icons.assignment_outlined, size: 56, color: Color(0xFFCBD5E1)),
            SizedBox(height: 16),
            Text(
              'Belum Ada E-Rapor',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: darkSlate),
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