import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
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
    try {
      final response = await http.get(
        Uri.parse(widget.pdfUrl),
        headers: {'Authorization': 'Bearer ${widget.authToken}'},
      );

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/rapor_temp.pdf');
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          localFilePath = file.path;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Gagal mengunduh file PDF (Status: ${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan saat memuat PDF: $e';
        isLoading = false;
      });
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
          : PDFView(
        filePath: localFilePath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
      ),
    );
  }
}

