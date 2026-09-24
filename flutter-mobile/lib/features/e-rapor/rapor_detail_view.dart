import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'viewmodel/rapor_viewmodel.dart';
import 'models/rapor_model.dart';
import '../auth/viewmodel/auth_viewmodel.dart';
import '../widgets/custom_pdf_viewer.dart';
import '../widgets/shared_header.dart';

class RaporDetailViewPage extends StatefulWidget {
  final int raporId;
  final String authToken;

  const RaporDetailViewPage({
    super.key,
    required this.raporId,
    required this.authToken,
  });

  @override
  State<RaporDetailViewPage> createState() => _RaporDetailViewPageState();
}

class _RaporDetailViewPageState extends State<RaporDetailViewPage> {
  static const Color primaryTeal = Color(0xFF059669);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color backgroundSlate = Color(0xFFF8FAFC);
  static const Color borderSlate = Color(0xFFE2E8F0);

  Uint8List? _generatedPdfBytes;
  bool _isGeneratingPdf = false;
  String? _pdfError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataAndGeneratePdf();
    });
  }

  Future<void> _loadDataAndGeneratePdf() async {
    final vm = context.read<RaporViewModel>();
    final authVm = context.read<AuthViewModel>();

    // 1. Fetch data detail JSON dari ViewModel (force refresh dari API)
    await vm.fetchReportDetail(widget.authToken, widget.raporId, forceRefresh: true);

    // 2. Jika data berhasil didapatkan, buat bytes PDF secara in-memory
    if (vm.currentDetail != null && mounted) {
      setState(() {
        _isGeneratingPdf = true;
        _pdfError = null;
      });

      try {
        ReportCardHeader? header;
        try {
          header = vm.reports.firstWhere((r) => r.id == widget.raporId);
        } catch (_) {}

        final pdfBytes = await vm.generatePdf(
          vm.currentDetail!,
          header,
          authVm.user,
        );

        if (mounted) {
          setState(() {
            _generatedPdfBytes = pdfBytes;
            _isGeneratingPdf = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _pdfError = 'Gagal membuat dokumen PDF: $e';
            _isGeneratingPdf = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundSlate,
      appBar: SharedHeader(
        title: 'DETAIL E-RAPOR DIKNAS',
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
      body: Consumer<RaporViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading || _isGeneratingPdf) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: primaryTeal),
                  SizedBox(height: 12),
                  Text(
                    'Membuat dokumen PDF...',
                    style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                ],
              ),
            );
          }

          if (vm.errorMessage != null || _pdfError != null) {
            return _buildError(vm.errorMessage ?? _pdfError!);
          }

          if (_generatedPdfBytes == null) {
            return const Center(
              child: Text('Detail rapor tidak ditemukan.'),
            );
          }

          final studentName = vm.currentDetail?.studentName ?? 'Siswa';
          return CustomPdfViewer(
            pdfBytes: _generatedPdfBytes!,
            fileName: 'E-Rapor_${studentName}_ID${widget.raporId}.pdf',
          );
        },
      ),
    );
  }

  Widget _buildError(String errorMessage) {
    return RefreshIndicator(
      color: primaryTeal,
      onRefresh: _loadDataAndGeneratePdf,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDataAndGeneratePdf,
                style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
                child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}