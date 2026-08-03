import 'package:flutter/material.dart';
import 'widgets/cbt/cbt_header_card.dart';
import 'widgets/cbt/cbt_filter_tabs.dart';
import 'widgets/cbt/cbt_exam_card.dart';

class CbtListView extends StatefulWidget {
  const CbtListView({super.key});

  @override
  State<CbtListView> createState() => _CbtListViewState();
}

class _CbtListViewState extends State<CbtListView> {
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color backgroundSlate = Color(0xFFF8FAFC);
  
  String _selectedTab = 'Semua';
  final List<String> _tabs = ['Semua', 'Aktif', 'Selesai'];

  // Data dummy ujian
  final List<Map<String, dynamic>> _exams = [
    {
      'subject': 'Matematika Wajib',
      'examType': 'Ujian Tengah Semester',
      'date': '30 Juli 2026',
      'time': '08:00 - 10:00 WIB',
      'duration': 120,
      'questionCount': 40,
      'status': 'Aktif',
    },
    {
      'subject': 'Bahasa Indonesia',
      'examType': 'Ujian Tengah Semester',
      'date': '31 Juli 2026',
      'time': '08:00 - 09:30 WIB',
      'duration': 90,
      'questionCount': 50,
      'status': 'Belum Mulai',
    },
    {
      'subject': 'Fisika Dasar',
      'examType': 'Kuis Harian',
      'date': '28 Juli 2026',
      'time': '10:00 - 11:00 WIB',
      'duration': 60,
      'questionCount': 20,
      'status': 'Selesai',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredExams = _exams.where((exam) {
      if (_selectedTab == 'Semua') return true;
      return exam['status'] == _selectedTab;
    }).toList();

    final activeCount = _exams.where((e) => e['status'] == 'Aktif').length;

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
          'JADWAL UJIAN CBT',
          style: TextStyle(color: darkSlate, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CbtHeaderCard(activeExamCount: activeCount),
            const SizedBox(height: 20),
            CbtFilterTabs(
              tabs: _tabs,
              selectedTab: _selectedTab,
              onTabChanged: (tab) => setState(() => _selectedTab = tab),
            ),
            const SizedBox(height: 20),
            if (filteredExams.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text('Tidak ada ujian pada kategori ini.', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredExams.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final exam = filteredExams[index];
                  return CbtExamCard(
                    subject: exam['subject'],
                    examType: exam['examType'],
                    date: exam['date'],
                    time: exam['time'],
                    duration: exam['duration'],
                    questionCount: exam['questionCount'],
                    status: exam['status'],
                    onActionTap: () {
                      // Logika navigasi ke halaman ujian atau halaman hasil
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// Model Data Ujian
class ExamItem {
  final int id;
  final String title;
  final String subject;
  final String dateTime;
  final String duration;
  final String status;
  final String tokenHint;

  ExamItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.dateTime,
    required this.duration,
    required this.status,
    required this.tokenHint,
  });
}