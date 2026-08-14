// lib/rapor_detail_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodel/rapor_viewmodel.dart';
import 'models/rapor_model.dart';
import 'widgets/rapor_header_card.dart';
import 'widgets/rapor_notes_card.dart';
import 'widgets/rapor_subject_card.dart';
import 'widgets/pdf_viewer_page.dart';

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
  static const Color textSlate = Color(0xFF475569);
  static const Color borderSlate = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RaporViewModel>().fetchReportDetail(widget.authToken, widget.raporId);
    });
  }

  void _openPdfPreview(String pdfUrl, String fileName) {
    // Susun URL lengkap backend jika path bersifat relatif
    final fullUrl = pdfUrl.startsWith('http')
        ? pdfUrl
        : 'https://domain-backend-anda.com$pdfUrl';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          pdfUrl: fullUrl,
          title: fileName,
          authToken: widget.authToken,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RaporViewModel>();
    final detail = vm.currentDetail;

    ReportCardHeader? header;
    try {
      header = vm.reports.firstWhere((r) => r.id == widget.raporId);
    } catch (_) {}

    final semesterText = header?.semester ?? 'Semester -';
    final statusText = header?.decisionStatus ?? '-';
    final pdfUrl = detail?.pdfUrl ?? header?.pdfUrl;
    final fileName = detail?.fileName ?? header?.fileName ?? 'File Rapor.pdf';
    final hasPdf = pdfUrl != null && pdfUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: backgroundSlate,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: darkSlate, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'DETAIL E-RAPOR DIKNAS',
          style: TextStyle(
            color: darkSlate,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          if (hasPdf)
            IconButton(
              icon: const Icon(Icons.download_rounded, color: primaryTeal, size: 22),
              onPressed: () => _openPdfPreview(pdfUrl, fileName),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderSlate, height: 1),
        ),
      ),
      body: vm.isLoading && detail == null
          ? const Center(child: CircularProgressIndicator())
          : vm.errorMessage != null && detail == null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            vm.errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : detail == null
          ? const Center(
        child: Text('Detail rapor tidak ditemukan.'),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RaporHeaderCard(
              studentName: detail.studentName,
              semester: semesterText,
              averageScore: detail.averageScore.toStringAsFixed(1),
            ),
            const SizedBox(height: 16),
            if (hasPdf) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderSlate),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: darkSlate,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            'Dokumen Resmi E-Rapor',
                            style: TextStyle(fontSize: 10, color: textSlate),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _openPdfPreview(pdfUrl, fileName),
                      icon: const Icon(Icons.download, size: 16, color: primaryTeal),
                      label: const Text(
                        'Unduh',
                        style: TextStyle(color: primaryTeal, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            RaporNotesCard(
              teacherNotes: detail.teacherNotes,
              statusText: statusText,
            ),
            const SizedBox(height: 20),
            const Text(
              'RINCIAN NILAI MATA PELAJARAN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: textSlate,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            if (detail.subjects.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: detail.subjects.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final subject = detail.subjects[index];
                  return RaporSubjectCard(
                    subjectName: subject.subjectName,
                    teacherName: 'Mata Pelajaran Wajib',
                    knowledgeScore: subject.nilaiPengetahuan.toInt(),
                    skillScore: subject.nilaiKeterampilan.toInt(),
                    predicate: subject.predicate,
                  );
                },
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'Belum ada rincian mata pelajaran.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}