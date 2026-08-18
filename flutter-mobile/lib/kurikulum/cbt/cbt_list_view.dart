import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/viewmodel/auth_viewmodel.dart';
import 'widgets/cbt/cbt_header_card.dart';
import 'widgets/cbt/cbt_filter_tabs.dart';
import 'widgets/cbt/cbt_exam_card.dart';
import 'viewmodel/cbt_viewmodel.dart';
import 'verifikasi_token_view.dart';
import '../../widgets/shared_header.dart';

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

  // Data diambil dari middleware melalui CbtViewModel

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthViewModel>(context, listen: false);
      final cbtVm = Provider.of<CbtViewModel>(context, listen: false);
      final token = auth.token;
      if (token.isNotEmpty) {
        cbtVm.fetchCbtSchedules(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cbtVm = Provider.of<CbtViewModel>(context);
    final rawExams = cbtVm.exams;

    final filteredExams = rawExams.where((exam) {
      if (_selectedTab == 'Semua') return true;
      return (exam['status'] ?? '').toString() == _selectedTab;
    }).toList();

    final activeCount = rawExams.where((e) => (e['status'] ?? '').toString().toLowerCase() == 'aktif' || (e['status'] ?? '').toString().toLowerCase() == 'active').length;

    return Scaffold(
      backgroundColor: backgroundSlate,
      appBar: SharedHeader(
        title: 'JADWAL UJIAN CBT',
        backgroundColor: Colors.white,
        foregroundColor: darkSlate,
        centerTitle: true,
        elevation: 0,
        showBackButton: true,
        onBack: () => Navigator.pop(context),
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
            if (cbtVm.isLoading)
              const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: CircularProgressIndicator()))
            else if (cbtVm.errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(cbtVm.errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              )
            else if (filteredExams.isEmpty)
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
                  final subject = exam['mata_pelajaran'] ?? exam['judul_ujian'] ?? '';
                  final examType = exam['jenis_ujian'] ?? '';
                  final rentang = exam['rentang_waktu'] ?? '';
                  final duration = exam['durasi_menit'] ?? 0;
                  final questionCount = exam['jumlah_soal'] ?? 0;
                  final status = exam['status'] ?? '';

                  return CbtExamCard(
                    subject: subject.toString(),
                    examType: examType.toString(),
                    date: rentang.toString(),
                    time: '',
                    duration: int.tryParse(duration.toString()) ?? 0,
                    questionCount: int.tryParse(questionCount.toString()) ?? 0,
                    status: status.toString(),
                    onActionTap: () {
                      final token = Provider.of<AuthViewModel>(context, listen: false).token;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VerifikasiTokenView(
                            subject: subject.toString(),
                            jadwalId: exam['id'] as int? ?? 0,
                            authToken: token,
                          ),
                        ),
                      );
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