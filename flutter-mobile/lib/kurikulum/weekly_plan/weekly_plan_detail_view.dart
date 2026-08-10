import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class WeeklyPlanDetailScreen extends StatefulWidget {
  const WeeklyPlanDetailScreen({super.key});

  @override
  State<WeeklyPlanDetailScreen> createState() => _WeeklyPlanDetailScreenState();
}

class _WeeklyPlanDetailScreenState extends State<WeeklyPlanDetailScreen> {
  late PdfViewerController _pdfViewerController;
  int currentPage = 1;
  int pageCount = 0;
  double zoom = 1.0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'DETAIL WEEKLY PLAN',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.8,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Detail Card Table
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0,
                ),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(2.0),
                  },
                  // Use light, modern dividers instead of hard border
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: Colors.grey.shade100,
                      width: 1.0,
                    ),
                  ),
                  children: [
                    _buildDetailRow(
                      context,
                      icon: Icons.school_rounded,
                      label: 'Kelas',
                      value: 'Kelas 1 SD',
                    ),
                    _buildDetailRow(
                      context,
                      icon: Icons.view_module_rounded,
                      label: 'Semester',
                      valueWidget: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green.shade100,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Semester 1',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ),
                    _buildDetailRow(
                      context,
                      icon: Icons.calendar_month_rounded,
                      label: 'Tahun Ajaran',
                      value: '2025/2026',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            // PDF Toolbar & Viewer Card
            Container(
              height: 550,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    // PDF Toolbar
                    Container(
                      color: Colors.grey.shade900,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // File name
                          const Expanded(
                            child: Text(
                              'WeeklyPlan_Kelas_1_SD.pdf',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Pagination Controls
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.chevron_left_rounded,
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: currentPage > 1
                                    ? () => _pdfViewerController.previousPage()
                                    : null,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$currentPage/${pageCount == 0 ? '--' : pageCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: currentPage < pageCount
                                    ? () => _pdfViewerController.nextPage()
                                    : null,
                              ),
                            ],
                          ),
                          const SizedBox(width: 6),
                          // Zoom & Download Controls
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: zoom > 1.0
                                    ? () {
                                        setState(() {
                                          double newZoom =
                                              (_pdfViewerController.zoomLevel -
                                                      0.25)
                                                  .clamp(1.0, 3.0);
                                          _pdfViewerController.zoomLevel =
                                              newZoom;
                                          zoom = newZoom;
                                        });
                                      }
                                    : null,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(zoom * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: zoom < 3.0
                                    ? () {
                                        setState(() {
                                          double newZoom =
                                              (_pdfViewerController.zoomLevel +
                                                      0.25)
                                                  .clamp(1.0, 3.0);
                                          _pdfViewerController.zoomLevel =
                                              newZoom;
                                          zoom = newZoom;
                                        });
                                      }
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.download_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Mengunduh PDF...'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // PDF Viewer Area (using SfPdfViewer)
                    Expanded(
                      child: SfPdfViewer.asset(
                        'assets/WeeklyPlan_Kelas_1_SD.pdf',
                        controller: _pdfViewerController,
                        onPageChanged: (PdfPageChangedDetails details) {
                          setState(() {
                            currentPage = details.newPageNumber;
                          });
                        },
                        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                          setState(() {
                            pageCount = _pdfViewerController.pageCount;
                          });
                        },
                        onZoomLevelChanged: (PdfZoomDetails details) {
                          setState(() {
                            zoom = details.newZoomLevel;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? value,
    Widget? valueWidget,
  }) {
    return TableRow(
      children: [
        // Label Side
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.teal.shade600),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Value Side
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child:
                valueWidget ??
                Text(
                  value ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
          ),
        ),
      ],
    );
  }
}
