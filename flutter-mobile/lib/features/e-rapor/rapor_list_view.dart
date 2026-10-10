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
  static const Color primaryTeal = Color(0xFF059669);
  static const Color warmAmber = Color(0xFFF59E0B);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color backgroundSlate = Color(0xFFF8FAFC);
  static const Color textSlate = Color(0xFF475569);
  static const Color borderSlate = Color(0xFFE2E8F0);

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
      body: AppRefreshIndicator(
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
                itemCount: vm.reports.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, i) => _buildCard(context, vm.reports[i]),
              ),
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
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: () => _openPdf(context, report),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: warmAmber, width: 5)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildReportField(
                          'Jenis Rapor',
                          report.reportType,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildReportField('Tahun', report.academicYear),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildReportField('Semester', report.semester),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildReportField('Kelas', report.className),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textSlate,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: darkSlate,
          ),
        ),
      ],
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
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
