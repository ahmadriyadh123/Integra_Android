import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'; // 👈 Tambah ini untuk handle izin storage
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class CustomPdfViewer extends StatefulWidget {
  final Uint8List? pdfBytes;
  final String? filePath;
  final String fileName;

  const CustomPdfViewer({
    super.key,
    this.pdfBytes,
    this.filePath,
    this.fileName = 'Dokumen.pdf',
  }) : assert(pdfBytes != null || filePath != null,
            'pdfBytes atau filePath harus disediakan');

  @override
  State<CustomPdfViewer> createState() => _CustomPdfViewerState();
}

class _CustomPdfViewerState extends State<CustomPdfViewer> {
  late PdfViewerController _pdfViewerController;
  int _currentPage = 1;
  int _pageCount = 0;
  double _zoomLevel = 1.0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _pdfViewerController.previousPage();
    }
  }

  void _nextPage() {
    if (_pageCount > 0 && _currentPage < _pageCount) {
      _pdfViewerController.nextPage();
    }
  }

  void _zoomIn() {
    final nextZoom = (_zoomLevel + 0.25).clamp(1.0, 4.0);
    _pdfViewerController.zoomLevel = nextZoom;
    setState(() {
      _zoomLevel = nextZoom;
    });
  }

  void _zoomOut() {
    final nextZoom = (_zoomLevel - 0.25).clamp(1.0, 4.0);
    _pdfViewerController.zoomLevel = nextZoom;
    setState(() {
      _zoomLevel = nextZoom;
    });
  }

  /// Helper untuk meminta izin penyimpanan pada Android
  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }
      // Untuk Android 11+ (API 30+) jika akses ke folder publik membutuhkan izin khusus
      if (await Permission.manageExternalStorage.isDenied) {
        await Permission.manageExternalStorage.request();
      }
    }
  }

  Future<void> _downloadPdf() async {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
    });

    try {
      // 1. Minta izin storage sebelum menulis file
      await _requestStoragePermission();

      // 2. Baca bytes dokumen
      Uint8List? bytes = widget.pdfBytes;
      if (bytes == null && widget.filePath != null) {
        bytes = await File(widget.filePath!).readAsBytes();
      }

      if (bytes == null || bytes.isEmpty) {
        throw Exception('Data dokumen PDF kosong.');
      }

      // 3. Format nama file agar bersih
      String saveName = widget.fileName;
      if (!saveName.toLowerCase().endsWith('.pdf')) {
        saveName = '$saveName.pdf';
      }
      final sanitizedFileName = saveName.replaceAll(RegExp(r'[^\w\s\.-]'), '_');

      // 4. Tentukan folder tujuan penyimpanan
      Directory? targetDir;
      if (Platform.isAndroid) {
        targetDir = Directory('/storage/emulated/0/Download');
        if (!await targetDir.exists()) {
          targetDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        targetDir = await getApplicationDocumentsDirectory();
      } else {
        targetDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }

      // 5. Tulis byte file fisik
      if (targetDir != null) {
        final file = File('${targetDir.path}/$sanitizedFileName');
        await file.writeAsBytes(bytes, flush: true);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Berhasil mengunduh $sanitizedFileName',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Bagikan',
                textColor: Colors.white,
                onPressed: () {
                  Printing.sharePdf(bytes: bytes!, filename: sanitizedFileName);
                },
              ),
            ),
          );
        }
      } else {
        // Fallback share jika folder penyimpanan tidak dapat diakses
        await Printing.sharePdf(bytes: bytes, filename: sanitizedFileName);
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (mounted) {
        // Fallback saat error: Buka dialog native share PDF
        if (widget.pdfBytes != null) {
          try {
            await Printing.sharePdf(
              bytes: widget.pdfBytes!,
              filename: widget.fileName,
            );
          } catch (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal mengunduh file: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar Bar
        _buildToolbar(),

        // PDF View Area
        Expanded(
          child: widget.pdfBytes != null
              ? SfPdfViewer.memory(
                  widget.pdfBytes!,
                  controller: _pdfViewerController,
                  canShowScrollHead: true,
                  canShowScrollStatus: true,
                  onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                    setState(() {
                      _pageCount = details.document.pages.count;
                      _currentPage = _pdfViewerController.pageNumber;
                    });
                  },
                  onPageChanged: (PdfPageChangedDetails details) {
                    setState(() {
                      _currentPage = details.newPageNumber;
                    });
                  },
                  onZoomLevelChanged: (details) {
                    setState(() {
                      _zoomLevel = details.newZoomLevel;
                    });
                  },
                )
              : SfPdfViewer.file(
                  File(widget.filePath!),
                  controller: _pdfViewerController,
                  canShowScrollHead: true,
                  canShowScrollStatus: true,
                  onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                    setState(() {
                      _pageCount = details.document.pages.count;
                      _currentPage = _pdfViewerController.pageNumber;
                    });
                  },
                  onPageChanged: (PdfPageChangedDetails details) {
                    setState(() {
                      _currentPage = details.newPageNumber;
                    });
                  },
                  onZoomLevelChanged: (details) {
                    setState(() {
                      _zoomLevel = details.newZoomLevel;
                    });
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    final bool canPrev = _currentPage > 1;
    final bool canNext = _pageCount > 0 && _currentPage < _pageCount;
    final bool canZoomOut = _zoomLevel > 1.0;
    final bool canZoomIn = _zoomLevel < 4.0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 360;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Navigation Tools
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: canPrev ? _previousPage : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                        tooltip: 'Sebelumnya',
                        iconSize: 20,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        color: const Color(0xFF0F172A),
                        disabledColor: const Color(0xFFCBD5E1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '${_currentPage} / ${_pageCount == 0 ? '-' : _pageCount}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: canNext ? _nextPage : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                        tooltip: 'Selanjutnya',
                        iconSize: 20,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        color: const Color(0xFF0F172A),
                        disabledColor: const Color(0xFFCBD5E1),
                      ),
                    ],
                  ),
                ),

                // 2. Zoom Tools
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: canZoomOut ? _zoomOut : null,
                        icon: const Icon(Icons.remove_rounded),
                        tooltip: 'Zoom Out',
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        color: const Color(0xFF0F172A),
                        disabledColor: const Color(0xFFCBD5E1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '${(_zoomLevel * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: canZoomIn ? _zoomIn : null,
                        icon: const Icon(Icons.add_rounded),
                        tooltip: 'Zoom In',
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        color: const Color(0xFF0F172A),
                        disabledColor: const Color(0xFFCBD5E1),
                      ),
                    ],
                  ),
                ),

                // 3. Download Tool
                Material(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: _isDownloading ? null : _downloadPdf,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 8 : 12,
                        vertical: 7,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isDownloading)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            const Icon(
                              Icons.download_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          if (!isCompact) ...[
                            const SizedBox(width: 4),
                            const Text(
                              'Unduh',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}