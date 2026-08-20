import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import 'viewmodel/buku_komunikasi_viewmodel.dart';
import 'models/buku_komunikasi_model.dart';
import 'widgets/student_info_banner.dart';
import 'widgets/month_week_filter.dart';
import 'widgets/daily_note_card.dart';
import '../../widgets/shared_header.dart';

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
  static const List<String> _monthOptions = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  static const List<String> _weekOptions = [
    'Pekan 1',
    'Pekan 2',
    'Pekan 3',
    'Pekan 4',
  ];

  String? _selectedMonth;
  String? _selectedWeek;
  int? _lastLineId;

  // Map of controllers for each day
  final Map<String, TextEditingController> _responseControllers = {
    'senin': TextEditingController(),
    'selasa': TextEditingController(),
    'rabu': TextEditingController(),
    'kamis': TextEditingController(),
    'jumat': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthViewModel>().token;
      context.read<BukuKomunikasiViewModel>().fetchBukuKomunikasi(token);
    });
  }

  @override
  void dispose() {
    for (var controller in _responseControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submitFeedback(int lineId, String dayKey) async {
    final token = context.read<AuthViewModel>().token;
    final feedbackText = _responseControllers[dayKey]!.text;
    
    final success = await context.read<BukuKomunikasiViewModel>().submitFeedback(
      token: token,
      lineId: lineId,
      day: dayKey,
      feedbackText: feedbackText.isEmpty ? '-' : feedbackText,
    );
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catatan/respons berhasil disimpan!'),
            backgroundColor: primaryTeal,
          ),
        );
      } else {
        final error = context.read<BukuKomunikasiViewModel>().errorMessage ?? 'Gagal menyimpan respons';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BukuKomunikasiViewModel>();
    final detail = vm.detail;
    final lines = detail?.lines ?? [];

    // Keep all calendar periods selectable, including periods without data.
    final List<String> months = _monthOptions;
    final List<String> weeks = _weekOptions;

    // Determine current selections
    final String? currentMonth = months.contains(_selectedMonth)
      ? _selectedMonth
      : (months.isNotEmpty ? months.first : null);
    final String? currentWeek = weeks.contains(_selectedWeek)
      ? _selectedWeek
      : weeks.first;

    // Find current line matching criteria
    final selectedWeekNum = currentWeek != null ? int.tryParse(currentWeek.replaceAll('Pekan ', '')) : null;
    final matchingLines = lines.where(
          (l) => l.bulan.trim().toLowerCase() == currentMonth?.toLowerCase() &&
              l.pekanKe == selectedWeekNum,
    );
    final DailyNoteLine? selectedLine = matchingLines.isNotEmpty
      ? matchingLines.first
      : null;

    // Update controllers value when selection changes
    if (selectedLine != null && selectedLine.id != _lastLineId) {
      _lastLineId = selectedLine.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _responseControllers['senin']!.text = selectedLine.feedbackSenin == '-' ? '' : selectedLine.feedbackSenin;
        _responseControllers['selasa']!.text = selectedLine.feedbackSelasa == '-' ? '' : selectedLine.feedbackSelasa;
        _responseControllers['rabu']!.text = selectedLine.feedbackRabu == '-' ? '' : selectedLine.feedbackRabu;
        _responseControllers['kamis']!.text = selectedLine.feedbackKamis == '-' ? '' : selectedLine.feedbackKamis;
        _responseControllers['jumat']!.text = selectedLine.feedbackJumat == '-' ? '' : selectedLine.feedbackJumat;
      });
    }

    final List<Map<String, dynamic>> dailyNotes = selectedLine != null ? [
      {
        'day': 'Senin',
        'key': 'senin',
        'note': selectedLine.senin,
      },
      {
        'day': 'Selasa',
        'key': 'selasa',
        'note': selectedLine.selasa,
      },
      {
        'day': 'Rabu',
        'key': 'rabu',
        'note': selectedLine.rabu,
      },
      {
        'day': 'Kamis',
        'key': 'kamis',
        'note': selectedLine.kamis,
      },
      {
        'day': 'Jumat',
        'key': 'jumat',
        'note': selectedLine.jumat,
      },
    ] : [];

    return Scaffold(
      backgroundColor: backgroundSlate,
      appBar: SharedHeader(
        title: 'BUKU KOMUNIKASI',
        backgroundColor: Colors.white,
        foregroundColor: darkSlate,
        centerTitle: true,
        elevation: 0,
        showBackButton: true,
        onBack: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryTeal, size: 22),
            onPressed: () {
              final token = context.read<AuthViewModel>().token;
              context.read<BukuKomunikasiViewModel>().fetchBukuKomunikasi(token);
            },
          ),
        ],
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
                      child: Text('Data buku komunikasi tidak ditemukan untuk siswa ini'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StudentInfoBanner(
                            studentName: detail.studentName,
                            className: detail.className,
                            academicYear: detail.academicYear,
                            status: detail.status,
                          ),
                          const SizedBox(height: 16),
                          if (months.isNotEmpty && weeks.isNotEmpty) ...[
                            MonthWeekFilter(
                              selectedMonth: currentMonth!,
                              selectedWeek: currentWeek!,
                              months: months,
                              weeks: weeks,
                              onMonthChanged: (val) {
                                setState(() => _selectedMonth = val);
                              },
                              onWeekChanged: (val) => setState(() => _selectedWeek = val),
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
                                  '$currentMonth • $currentWeek',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primaryTeal),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (dailyNotes.isNotEmpty)
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: dailyNotes.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 14),
                                itemBuilder: (context, index) {
                                  final note = dailyNotes[index];
                                  final dayKey = note['key'] as String;
                                  final noteText = note['note'] as String;
                                  final hasDailyContent = noteText.trim().isNotEmpty && noteText != '-';

                                  return DailyNoteCard(
                                    day: note['day'] as String,
                                    date: '$currentWeek, $currentMonth',
                                    hasTeacherNote: false,
                                    savedResponse: hasDailyContent ? noteText : null,
                                    responseController: _responseControllers[dayKey]!,
                                    onSubmitResponse: () => _submitFeedback(selectedLine!.id, dayKey),
                                  );
                                },
                              )
                            else
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Text('Tidak ada rincian catatan harian untuk pekan ini.', style: TextStyle(color: Colors.grey)),
                                ),
                              ),
                          ] else
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Text('Belum ada data catatan untuk kelas Anda.', style: TextStyle(color: Colors.grey)),
                              ),
                            ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }
}