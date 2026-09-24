import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import 'viewmodel/buku_komunikasi_viewmodel.dart';
import 'models/buku_komunikasi_model.dart';
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
  String? _lastFormKey;

  // Map of controllers for each day
  final Map<String, TextEditingController> _noteControllers = {
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
    for (var controller in _noteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submitNote(int? lineId, String dayKey, String? month, String? week) async {
    final token = context.read<AuthViewModel>().token;
    final noteText = _noteControllers[dayKey]!.text.trim();
    
    if (noteText.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan tidak boleh kosong.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedWeekNum = week != null ? int.tryParse(week.replaceAll('Pekan ', '')) : 1;

    final success = await context.read<BukuKomunikasiViewModel>().submitDailyNote(
      token: token,
      lineId: lineId ?? 0,
      day: dayKey,
      noteText: noteText,
      month: month,
      week: selectedWeekNum,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catatan harian berhasil dikirim!'),
            backgroundColor: primaryTeal,
          ),
        );
      } else {
        final error = context.read<BukuKomunikasiViewModel>().errorMessage ?? 'Gagal menyimpan catatan';
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

    final List<String> months = _monthOptions;
    final List<String> weeks = _weekOptions;

    final String? currentMonth = months.contains(_selectedMonth)
      ? _selectedMonth
      : (months.isNotEmpty ? months.first : null);
    final String? currentWeek = weeks.contains(_selectedWeek)
      ? _selectedWeek
      : weeks.first;

    final selectedWeekNum = currentWeek != null ? int.tryParse(currentWeek.replaceAll('Pekan ', '')) : null;
    final matchingLines = lines.where(
          (l) => l.bulan.trim().toLowerCase() == currentMonth?.toLowerCase() &&
              l.pekanKe == selectedWeekNum,
    );
    final DailyNoteLine? selectedLine = matchingLines.isNotEmpty
      ? matchingLines.first
      : null;

    final formKey = '${selectedLine?.id ?? 'empty'}|$currentMonth|$currentWeek';
    if (_lastFormKey != formKey) {
      _lastFormKey = formKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (selectedLine != null) {
          _noteControllers['senin']!.text = selectedLine.senin == '-' ? '' : selectedLine.senin;
          _noteControllers['selasa']!.text = selectedLine.selasa == '-' ? '' : selectedLine.selasa;
          _noteControllers['rabu']!.text = selectedLine.rabu == '-' ? '' : selectedLine.rabu;
          _noteControllers['kamis']!.text = selectedLine.kamis == '-' ? '' : selectedLine.kamis;
          _noteControllers['jumat']!.text = selectedLine.jumat == '-' ? '' : selectedLine.jumat;
        } else {
          for (final controller in _noteControllers.values) {
            controller.clear();
          }
        }
      });
    }

    final List<Map<String, dynamic>> dailyNotes = [
      {
        'day': 'Senin',
        'key': 'senin',
        'note': selectedLine?.senin ?? '-',
        'feedback': selectedLine?.feedbackSenin ?? '-',
      },
      {
        'day': 'Selasa',
        'key': 'selasa',
        'note': selectedLine?.selasa ?? '-',
        'feedback': selectedLine?.feedbackSelasa ?? '-',
      },
      {
        'day': 'Rabu',
        'key': 'rabu',
        'note': selectedLine?.rabu ?? '-',
        'feedback': selectedLine?.feedbackRabu ?? '-',
      },
      {
        'day': 'Kamis',
        'key': 'kamis',
        'note': selectedLine?.kamis ?? '-',
        'feedback': selectedLine?.feedbackKamis ?? '-',
      },
      {
        'day': 'Jumat',
        'key': 'jumat',
        'note': selectedLine?.jumat ?? '-',
        'feedback': selectedLine?.feedbackJumat ?? '-',
      },
    ];

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
      ),
      body: RefreshIndicator(
        color: primaryTeal,
        onRefresh: () async {
          final token = context.read<AuthViewModel>().token;
          await context.read<BukuKomunikasiViewModel>().fetchBukuKomunikasi(token);
        },
        child: vm.isLoading && detail == null
            ? const Center(child: CircularProgressIndicator())
            : vm.errorMessage != null && detail == null
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height * 0.7,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        vm.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : detail == null
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height * 0.7,
                          ),
                          alignment: Alignment.center,
                          child: const Text('Data buku komunikasi tidak ditemukan untuk siswa ini'),
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: dailyNotes.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 14),
                                itemBuilder: (context, index) {
                                  final note = dailyNotes[index];
                                  final dayKey = note['key'] as String;
                                  final noteText = note['note'] as String;
                                  final feedbackText = note['feedback'] as String;

                                  return DailyNoteCard(
                                    day: note['day'] as String,
                                    date: '$currentWeek, $currentMonth',
                                    savedNote: noteText != '-' ? noteText : null,
                                    teacherFeedback: feedbackText != '-' ? feedbackText : null,
                                    noteController: _noteControllers[dayKey]!,
                                    noLineRecord: false, // Diset false agar tombol kirim selalu aktif
                                    onSubmitNote: () => _submitNote(
                                      selectedLine?.id,
                                      dayKey,
                                      currentMonth,
                                      currentWeek,
                                    ),
                                  );
                                },
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
      ),
    );
  }
}