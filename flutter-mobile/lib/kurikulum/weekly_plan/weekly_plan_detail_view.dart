import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'viewmodel/weekly_plan_viewmodel.dart';
import '../../widgets/shared_header.dart';

class WeeklyPlanDetailScreen extends StatefulWidget {
  final int planId;
  final String title;
  final String authToken;

  const WeeklyPlanDetailScreen({
    super.key,
    required this.planId,
    required this.title,
    required this.authToken,
  });

  @override
  State<WeeklyPlanDetailScreen> createState() =>
      _WeeklyPlanDetailScreenState();
}

class _WeeklyPlanDetailScreenState extends State<WeeklyPlanDetailScreen> {
  static const Color primaryTeal = Color(0xFF059669);
  static const Color darkSlate   = Color(0xFF0F172A);
  static const Color bgSlate     = Color(0xFFF8FAFC);
  static const Color borderColor = Color(0xFFE2E8F0);

  late final String _pdfUrl;
  final PdfViewerController _pdfController = PdfViewerController();

  bool _isError = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    // Bangun URL PDF dari ViewModel — tidak perlu fetch JSON
    final vm = context.read<WeeklyPlanViewModel>();
    _pdfUrl = vm.getPdfUrl(widget.planId);
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSlate,
      appBar: SharedHeader(
        titleWidget: Text(
          widget.title,
          style: const TextStyle(
            color: darkSlate,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
            tooltip: 'Muat Ulang',
            onPressed: () {
              setState(() {
                _isError = false;
                _errorMsg = '';
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: _isError ? _buildError() : _buildPdfViewer(),
    );
  }

  Widget _buildPdfViewer() {
    return SfPdfViewer.network(
      _pdfUrl,
      headers: {'Authorization': 'Bearer ${widget.authToken}'},
      controller: _pdfController,
      onDocumentLoadFailed: (details) {
        setState(() {
          _isError = true;
          _errorMsg = details.description.isNotEmpty
              ? details.description
              : 'File PDF tidak dapat dimuat. Pastikan file sudah diupload oleh admin.';
        });
      },
      canShowScrollHead: true,
      canShowScrollStatus: true,
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
            const Text(
              'Gagal Memuat PDF',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: darkSlate),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMsg.isNotEmpty
                  ? _errorMsg
                  : 'File PDF belum tersedia untuk Weekly Plan ini.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {
                _isError = false;
                _errorMsg = '';
              }),
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
