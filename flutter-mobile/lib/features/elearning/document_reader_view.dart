import 'package:flutter/material.dart';
import 'widgets/document/document_top_bar.dart';
import 'widgets/document/document_viewer_area.dart';
import 'widgets/document/document_bottom_controls.dart';

class DocumentReaderView extends StatefulWidget {
  final String title;
  final String subject;

  const DocumentReaderView({
    super.key,
    this.title = 'Rangkuman_Aturan_Sinus.pdf',
    this.subject = 'Matematika Wajib',
  });

  @override
  State<DocumentReaderView> createState() => _DocumentReaderViewState();
}

class _DocumentReaderViewState extends State<DocumentReaderView> {
  int _currentPage = 1;
  final int _totalPages = 12; // Asumsi total halaman dokumen
  double _currentZoom = 1.0;

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
        _currentZoom = 1.0; // Reset zoom saat ganti halaman
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _currentZoom = 1.0; // Reset zoom saat ganti halaman
      });
    }
  }

  void _zoomIn() {
    setState(() {
      if (_currentZoom < 3.0) _currentZoom += 0.25;
    });
  }

  void _zoomOut() {
    setState(() {
      if (_currentZoom > 1.0) _currentZoom -= 0.25;
    });
  }

  void _handleDownload() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.downloading_rounded, color: Color(0xFFA7F3D0), size: 18),
            const SizedBox(width: 10),
            const Text('Mengunduh dokumen...', style: TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DocumentTopBar(
        title: widget.title,
        subject: widget.subject,
        onBackTap: () => Navigator.pop(context),
        onDownloadTap: _handleDownload,
      ),
      body: DocumentViewerArea(
        currentPage: _currentPage,
        totalPages: _totalPages,
        currentZoom: _currentZoom,
      ),
      bottomNavigationBar: DocumentBottomControls(
        currentPage: _currentPage,
        totalPages: _totalPages,
        onPreviousTap: _previousPage,
        onNextTap: _nextPage,
        onZoomInTap: _zoomIn,
        onZoomOutTap: _zoomOut,
      ),
    );
  }
}