import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/calendar_model.dart';
import 'viewmodel/calendar_viewmodel.dart';
import 'widgets/calendar_header_banner.dart';

class AcademicCalendarPage extends StatefulWidget {
  final String authToken;

  const AcademicCalendarPage({super.key, required this.authToken});

  @override
  State<AcademicCalendarPage> createState() => _AcademicCalendarPageState();
}

class _AcademicCalendarPageState extends State<AcademicCalendarPage> {
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color backgroundSlate = Color(0xFFF8FAFC);
  static const Color textSlate = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color primaryGreen = Color(0xFF059669);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<CalendarViewModel>();
      if (!vm.isLoading && !vm.hasData && vm.errorMessage == null) {
        vm.fetchCalendars(widget.authToken);
      }
    });
  }

  Future<void> _openLink(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'KALENDER AKADEMIK',
          style: TextStyle(
            color: darkSlate,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Consumer<CalendarViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            );
          }

          if (vm.errorMessage != null) {
            return _buildError(vm);
          }

          if (!vm.hasData) {
            return _buildEmpty();
          }

          return _buildContent(vm.calendars);
        },
      ),
    );
  }

  Widget _buildContent(List<CalendarItem> calendars) {
    // Ambil info kelas & tahun ajaran dari item pertama untuk header
    final firstItem = calendars.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CalendarHeaderBanner(
            activeMonth: firstItem.kelas,
            totalEvents: calendars.length,
          ),
          const SizedBox(height: 20),
          const Text(
            'DAFTAR KALENDER AKADEMIK',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textSlate,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: calendars.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildCalendarCard(calendars[index]),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(CalendarItem item) {
    final bool hasLink = item.linkDokumen.isNotEmpty;
    final statusColor = _statusColor(item.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: primaryGreen, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.school_rounded,
                        size: 14,
                        color: primaryGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.tahunAjaran,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Nama kelas
              Text(
                item.kelas,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: darkSlate,
                ),
              ),
              const SizedBox(height: 4),

              // Semester
              Row(
                children: [
                  const Icon(Icons.date_range_rounded,
                      size: 13, color: textMuted),
                  const SizedBox(width: 4),
                  Text(
                    item.semester,
                    style: const TextStyle(fontSize: 12, color: textSlate),
                  ),
                ],
              ),

              if (hasLink) ...[
                const SizedBox(height: 14),
                const Divider(height: 1, color: borderColor),
                const SizedBox(height: 12),
                // Tombol buka dokumen
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openLink(item.linkDokumen),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text(
                      'Buka Dokumen Kalender',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryGreen,
                      side: const BorderSide(color: primaryGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(CalendarViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Data',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: darkSlate),
            ),
            const SizedBox(height: 8),
            Text(
              vm.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: textSlate),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => vm.fetchCalendars(widget.authToken),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 56, color: Color(0xFFCBD5E1)),
            SizedBox(height: 16),
            Text(
              'Belum Ada Kalender',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: darkSlate),
            ),
            SizedBox(height: 8),
            Text(
              'Kalender akademik untuk kelas Anda belum tersedia.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textSlate),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return const Color(0xFF0284C7);
      case 'approved':
        return const Color(0xFF059669);
      case 'draft':
        return const Color(0xFF94A3B8);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return 'Diajukan';
      case 'approved':
        return 'Disetujui';
      case 'draft':
        return 'Draft';
      default:
        return status;
    }
  }
}
