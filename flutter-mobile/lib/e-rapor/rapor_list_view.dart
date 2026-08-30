import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'viewmodel/rapor_viewmodel.dart';
import 'models/rapor_model.dart';
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
  static const Color primaryTeal    = Color(0xFF059669);
  static const Color darkSlate      = Color(0xFF0F172A);
  static const Color backgroundSlate = Color(0xFFF8FAFC);
  static const Color textSlate      = Color(0xFF475569);
  static const Color borderSlate    = Color(0xFFE2E8F0);

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
    final vm = context.read<RaporViewModel>();
    final pdfUrl = vm.getPdfUrl(report.id);
    final title = 'Rapor ${report.semester} — ${report.academicYear}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _RaporPdfViewer(
          pdfUrl: pdfUrl,
          title: title,
          authToken: widget.authToken,
        ),
      ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: primaryTeal, size: 22),
            onPressed: vm.isLoading
                ? null
                : () => vm.fetchReportList(widget.authToken),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderSlate, height: 1),
        ),
      ),
      body: RefreshIndicator(
        color: primaryTeal,
        onRefresh: () => vm.fetchReportList(widget.authToken),
        child: vm.isLoading && vm.reports.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: primaryTeal))
            : vm.errorMessage != null
                ? _buildError(vm)
                : vm.reports.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: vm.reports.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) =>
                            _buildCard(context, vm.reports[i]),
                      ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, ReportCardHeader report) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSlate),
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
                left: BorderSide(color: primaryTeal, width: 4)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.school_rounded,
                          size: 14, color: primaryTeal),
                      const SizedBox(width: 5),
                      Text(
                        report.academicYear,
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
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Rata-rata: ${report.averageScore.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                report.semester,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: darkSlate,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.class_outlined,
                      size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    report.className,
                    style: const TextStyle(
                        fontSize: 12, color: textSlate),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: borderSlate),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openPdf(context, report),
                  icon: const Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 16),
                  label: const Text(
                    'Lihat E-Rapor PDF',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
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

  Widget _buildError(RaporViewModel vm) {
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
              onPressed: () =>
                  vm.fetchReportList(widget.authToken),
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
            Icon(Icons.assignment_outlined,
                size: 56, color: Color(0xFFCBD5E1)),
            SizedBox(height: 16),
            Text('Belum Ada E-Rapor',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: darkSlate)),
            SizedBox(height: 8),
            Text(
              'E-Rapor untuk semester ini belum tersedia.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textSlate),
            ),
          ],
        ),
      ),
    );
  }
}

class _RaporPdfViewer extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final String authToken;

  const _RaporPdfViewer({
    required this.pdfUrl,
    required this.title,
    required this.authToken,
  });

  @override
  State<_RaporPdfViewer> createState() => _RaporPdfViewerState();
}

class _RaporPdfViewerState extends State<_RaporPdfViewer> {
  static const Color primaryTeal = Color(0xFF059669);
  static const Color darkSlate   = Color(0xFF0F172A);
  static const Color borderSlate = Color(0xFFE2E8F0);

  final PdfViewerController _pdfController = PdfViewerController();
  bool _isError = false;
  String _errorMsg = '';

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: darkSlate, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: darkSlate,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_isError)
            IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: primaryTeal, size: 22),
              onPressed: () =>
                  setState(() => _isError = false),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderSlate, height: 1),
        ),
      ),
      body: _isError ? _buildError() : _buildViewer(),
    );
  }

  Widget _buildViewer() {
    return SfPdfViewer.network(
      widget.pdfUrl,
      headers: {'Authorization': 'Bearer ${widget.authToken}'},
      controller: _pdfController,
      onDocumentLoadFailed: (details) {
        setState(() {
          _isError = true;
          _errorMsg = details.description.isNotEmpty
              ? details.description
              : 'File PDF tidak dapat dimuat.';
        });
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf_rounded,
                size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text('Gagal Memuat PDF',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: darkSlate)),
            const SizedBox(height: 8),
            Text(
              _errorMsg.isNotEmpty
                  ? _errorMsg
                  : 'File PDF belum tersedia untuk rapor ini.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  setState(() => _isError = false),
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
}
