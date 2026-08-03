import 'package:flutter/material.dart';
import 'widgets/student_info_banner.dart';
import 'widgets/month_week_filter.dart';
import 'widgets/daily_note_card.dart';

// Model Data untuk Struktur Harian
class DailyNote {
  final String day;
  final String date;
  final bool hasTeacherNote;
  final String? teacherNote;

  DailyNote({
    required this.day,
    required this.date,
    this.hasTeacherNote = false,
    this.teacherNote,
  });
}

class BukuKomunikasiPage extends StatefulWidget {
  const BukuKomunikasiPage({super.key});

  @override
  State<BukuKomunikasiPage> createState() => _BukuKomunikasiPageState();
}

class _BukuKomunikasiPageState extends State<BukuKomunikasiPage> {
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color backgroundSlate = Color(0xFFF8FAFC);
  static const Color textSlate = Color(0xFF475569);
  static const Color primaryTeal = Color(0xFF059669);

  String _selectedMonth = 'April';
  String _selectedWeek = 'Pekan 4';

  // Map of controllers untuk tiap baris hari
  final Map<int, TextEditingController> _responseControllers = {};

  final List<DailyNote> _dailyNotes = [
    DailyNote(
      day: 'Senin',
      date: '21 Apr 2026',
      hasTeacherNote: true,
      teacherNote: 'Ananda hari ini sangat aktif di kelas matematika, mohon dipertahankan!',
    ),
    DailyNote(
      day: 'Selasa',
      date: '22 Apr 2026',
      hasTeacherNote: false,
    ),
    DailyNote(
      day: 'Rabu',
      date: '23 Apr 2026',
      hasTeacherNote: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller form berdasarkan index data
    for (int i = 0; i < _dailyNotes.length; i++) {
      _responseControllers[i] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _responseControllers.values) {
      controller.dispose();
    }
    super.dispose();
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
          'BUKU KOMUNIKASI',
          style: TextStyle(color: darkSlate, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.chat_bubble_outline, color: primaryTeal, size: 22),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StudentInfoBanner(
              studentName: 'Siswa 2',
              className: 'SD',
              academicYear: '2025/2026',
              status: 'Active',
            ),
            const SizedBox(height: 16),
            MonthWeekFilter(
              selectedMonth: _selectedMonth,
              selectedWeek: _selectedWeek,
              months: const ['April', 'Mei', 'Juni'],
              weeks: const ['Pekan 1', 'Pekan 2', 'Pekan 3', 'Pekan 4'],
              onMonthChanged: (val) => setState(() => _selectedMonth = val!),
              onWeekChanged: (val) => setState(() => _selectedWeek = val!),
            ),
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CATATAN PEKANAN',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textSlate, letterSpacing: 0.5),
                ),
                Text(
                  '$_selectedMonth • $_selectedWeek',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primaryTeal),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _dailyNotes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final note = _dailyNotes[index];
                return DailyNoteCard(
                  day: note.day,
                  date: note.date,
                  hasTeacherNote: note.hasTeacherNote,
                  teacherNote: note.teacherNote,
                  responseController: _responseControllers[index]!,
                  onSubmitResponse: () {
                    // Logic kirim data ke Odoo backend
                    final pesan = _responseControllers[index]!.text;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Pesan tersimpan: $pesan')),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}