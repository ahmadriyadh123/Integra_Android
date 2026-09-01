import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../widgets/custom_pdf_viewer.dart';
import '../../widgets/shared_header.dart';

class PdfViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final String authToken;

  const PdfViewerPage({
    super.key,
    required this.pdfUrl,
    required this.title,
    required this.authToken,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? localFilePath;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _downloadAndSavePdf();
  }

  Future<void> _downloadAndSavePdf() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final uri = Uri.parse(widget.pdfUrl);
      final isOdooWebDirect = uri.path.contains('/web/content/') || uri.port == 8069;

      List<Map<String, String>> headerAttempts = [];
      if (isOdooWebDirect) {
        headerAttempts.add({'User-Agent': 'FlutterApp/1.0'});
        if (widget.authToken.isNotEmpty) {
          headerAttempts.add({'Authorization': 'Bearer ${widget.authToken}'});
        }
      } else {
        if (widget.authToken.isNotEmpty) {
          headerAttempts.add({'Authorization': 'Bearer ${widget.authToken}'});
        }
        headerAttempts.add({'User-Agent': 'FlutterApp/1.0'});
      }

      debugPrint('PDF download start: ${widget.pdfUrl}');

      http.Response? response;
      Object? lastError;

      for (final headers in headerAttempts) {
        try {
          response = await http.get(uri, headers: headers).timeout(
            const Duration(seconds: 30),
          );
          if (response.statusCode == 200) {
            break;
          }
        } catch (e) {
          lastError = e;
        }
      }

      if (response != null && response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/rapor_temp_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          setState(() {
            localFilePath = file.path;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = response != null
                ? 'Gagal mengunduh file PDF (Status: ${response.statusCode})'
                : 'Terjadi kesalahan saat mengunduh PDF: ${lastError ?? 'Koneksi terputus'}';
            isLoading = false;
          });
        }
      }
    } catch (e, stack) {
      debugPrint('PDF download exception: $e\n$stack');
      if (mounted) {
        setState(() {
          errorMessage = 'Terjadi kesalahan saat memuat PDF: $e';
          isLoading = false;
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
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
          : CustomPdfViewer(
              filePath: localFilePath!,
              fileName: '${widget.title}.pdf',
            ),
    );
  }
}




