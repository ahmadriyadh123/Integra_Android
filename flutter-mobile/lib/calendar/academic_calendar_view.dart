import 'package:flutter/material.dart';
import 'widgets/calendar_header_banner.dart';
import 'widgets/event_legend_row.dart';
import 'widgets/agenda_item_card.dart';

class AcademicCalendarPage extends StatelessWidget {
  const AcademicCalendarPage({super.key});

  static const Color darkSlate = Color(0xFF0F172A);
  static const Color backgroundSlate = Color(0xFFF8FAFC);
  static const Color textSlate = Color(0xFF475569);

  // Data dummy agenda kalender akademik
  static final List<Map<String, dynamic>> _agendas = [
    {
      'dateRange': '01 - 05 Juli 2026',
      'title': 'Libur Semester Genap',
      'category': 'Libur Nasional',
      'description': 'Masa libur antar semester bagi seluruh siswa tingkat satuan pendidikan.',
      'color': const Color(0xFFEF4444),
    },
    {
      'dateRange': '13 Juli 2026',
      'title': 'Hari Pertama Masuk Sekolah & MPLS',
      'category': 'Kegiatan Sekolah',
      'description': 'Pembukaan tahun ajaran baru 2026/2027 dan Masa Pengenalan Lingkungan Sekolah.',
      'color': const Color(0xFF059669),
    },
    {
      'dateRange': '25 - 29 Juli 2026',
      'title': 'Ujian Tengah Semester (UTS) CBT',
      'category': 'Ujian / CBT',
      'description': 'Pelaksanaan asesmen tengah semester berbasis komputer serentak.',
      'color': const Color(0xFF0284C7),
    },
  ];

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CalendarHeaderBanner(
              activeMonth: 'Juli 2026',
              totalEvents: 3,
            ),
            const SizedBox(height: 16),
            const EventLegendRow(),
            const SizedBox(height: 20),
            const Text(
              'DAFTAR AGENDA BULAN INI',
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
              itemCount: _agendas.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final item = _agendas[index];
                return AgendaItemCard(
                  dateRange: item['dateRange'],
                  title: item['title'],
                  category: item['category'],
                  description: item['description'],
                  accentColor: item['color'],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}