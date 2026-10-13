import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/tenant_api_config.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../widgets/custom_pdf_viewer.dart';
import '../../widgets/shared_header.dart';
import '../viewmodel/rapor_viewmodel.dart';

class PdfViewerPage extends StatefulWidget {
  final int? raporId;
  final String? pdfUrl;
  final String title;
  final String authToken;

  const PdfViewerPage({
    super.key,
    this.raporId,
    this.pdfUrl,
    required this.title,
    required this.authToken,
  }) : assert((raporId == null) != (pdfUrl == null));

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf({bool forceRefresh = false}) async {
    if (forceRefresh) {
      setState(() {
        _isRefreshing = true;
        _errorMessage = null;
      });
    } else if (_pdfBytes == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      late final Uint8List pdfBytes;
      final pdfUrl = widget.pdfUrl;
      if (pdfUrl != null) {
        final tenantConfig = context.read<TenantApiConfig>();
        final response = await http
            .get(
              Uri.parse(pdfUrl),
              headers: tenantConfig.headers(
                token: widget.authToken,
                includeContentType: false,
              ),
            )
            .timeout(const Duration(seconds: 30));
        if (response.statusCode != 200) {
          throw Exception(
            'Gagal mengunduh file PDF (Status: ${response.statusCode})',
          );
        }
        pdfBytes = response.bodyBytes;
      } else {
        final viewModel = context.read<RaporViewModel>();
        if (!forceRefresh) {
          final cached = await viewModel.loadCachedReportPdf(
            widget.authToken,
            widget.raporId!,
          );
          if (cached != null && mounted) {
            setState(() {
              _pdfBytes = cached;
              _isLoading = false;
            });
            return;
          }
        }
        pdfBytes = await viewModel.getReportPdf(
          widget.authToken,
          widget.raporId!,
          forceRefresh: forceRefresh,
        );
      }
      if (mounted) {
        setState(() {
          _pdfBytes = pdfBytes;
          _errorMessage = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString().replaceFirst('Exception: ', '');
        });
        if (_pdfBytes != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memperbarui PDF: $_errorMessage')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SharedHeader(
        titleWidget: Text(widget.title, style: const TextStyle(fontSize: 14)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 1,
        showBackButton: true,
        actions: [
          IconButton(
            tooltip: 'Muat ulang PDF',
            onPressed: _isRefreshing
                ? null
                : () => _loadPdf(forceRefresh: true),
            icon: _isRefreshing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _pdfBytes != null
          ? CustomPdfViewer(
              pdfBytes: _pdfBytes!,
              fileName: '${widget.title}.pdf',
            )
          : _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _errorMessage ?? 'Dokumen PDF tidak ditemukan.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _loadPdf(forceRefresh: true),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
