// lib/rapor_list_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodel/rapor_viewmodel.dart';
import 'rapor_detail_view.dart';

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
  static const Color primaryTeal = Color(0xFF059669);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color backgroundSlate = Color(0xFFF8FAFC);
  static const Color textSlate = Color(0xFF475569);
  static const Color borderSlate = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RaporViewModel>().fetchReportList(widget.authToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RaporViewModel>();

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
          'DAFTAR E-RAPOR',
          style: TextStyle(
            color: darkSlate,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryTeal, size: 22),
            onPressed: () {
              context.read<RaporViewModel>().fetchReportList(widget.authToken);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderSlate, height: 1),
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.errorMessage != null
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
          : vm.reports.isEmpty
          ? const Center(
        child: Text(
          'Belum ada data E-Rapor tersedia.',
          style: TextStyle(color: textSlate, fontSize: 13),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: vm.reports.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final report = vm.reports[index];
          final hasFile = report.pdfUrl != null && report.pdfUrl!.isNotEmpty;

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RaporDetailViewPage(
                    raporId: report.id,
                    authToken: widget.authToken,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderSlate),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryTeal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      hasFile ? Icons.picture_as_pdf_rounded : Icons.assignment_turned_in_rounded,
                      color: primaryTeal,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rapor ${report.semester}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: darkSlate,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tahun Ajaran ${report.academicYear}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: textSlate,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
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
                            if (hasFile)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'PDF Ready',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: textSlate,
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}