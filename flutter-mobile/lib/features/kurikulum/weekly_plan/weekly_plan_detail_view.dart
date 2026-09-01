import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'viewmodel/weekly_plan_viewmodel.dart';
import '../../widgets/custom_pdf_viewer.dart';
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
  State<WeeklyPlanDetailScreen> createState() => _WeeklyPlanDetailScreenState();
}

class _WeeklyPlanDetailScreenState extends State<WeeklyPlanDetailScreen> {
  static const Color primaryTeal = Color(0xFF059669);
  static const Color darkSlate   = Color(0xFF0F172A);
  static const Color bgSlate     = Color(0xFFF8FAFC);
  static const Color borderColor = Color(0xFFE2E8F0);

  Uint8List? _generatedPdfBytes;
  bool _isGeneratingPdf = false;
  String? _pdfError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Memanggil ViewModel melalui kaskade Clean Architecture
      context.read<WeeklyPlanViewModel>().fetchPdfFile(
            widget.planId,
            widget.authToken,
          );
    });
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: Consumer<WeeklyPlanViewModel>(
        builder: (context, vm, _) {
          // 1. Loading State
          if (vm.isGeneratingPdf) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: primaryTeal),
                  SizedBox(height: 12),
                  Text(
                    'Mengunduh dokumen PDF...',
                    style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                ],
              ),
            );
          }

          // 2. Error State
          if (vm.pdfError != null) {
            return _buildError(vm.pdfError!, vm);
          }

          // 3. Empty State
          if (vm.pdfBytes == null) {
            return const Center(
              child: Text('Dokumen PDF tidak ditemukan.'),
            );
          }

          // 4. Success State (Render PDF Bytes dengan Tools Unduh, Zoom, & Halaman)
          return CustomPdfViewer(
            pdfBytes: vm.pdfBytes!,
            fileName: '${widget.title}.pdf',
          );
        },
      ),
    );
  }

  // Tipe parameter disesuaikan dari WeeklyPlanViewModel menjadi String errorMessage
  Widget _buildError(String errorMessage, WeeklyPlanViewModel vm) {
    return RefreshIndicator(
      color: primaryTeal,
      onRefresh: () => vm.fetchPdfFile(widget.planId, widget.authToken),
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
              const Icon(Icons.error_outline_rounded, size: 56, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 16),
              const Text(
                'Gagal Memuat PDF',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: darkSlate),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => vm.fetchPdfFile(widget.planId, widget.authToken),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}