import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodel/cbt_viewmodel.dart';
import '../../widgets/shared_header.dart';

class CbtExamView extends StatefulWidget {
  final String subject;
  final int jadwalId;
  final String authToken;

  const CbtExamView({
    super.key,
    required this.subject,
    required this.jadwalId,
    required this.authToken,
  });

  @override
  State<CbtExamView> createState() => _CbtExamViewState();
}

class _CbtExamViewState extends State<CbtExamView> {
  static const Color primaryColor = Color(0xFF059669);
  static const Color primaryLightColor = Color(0xFFECFDF5);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color backgroundSlate = Color(0xFFF8FAFC);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color dangerColor = Color(0xFFE11D48);

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _examData;
  List<Map<String, dynamic>> _questions = [];

  int _currentIndex = 0;
  final Map<int, int> _selectedAnswers = {}; // Map question index to option_id
  final Set<int> _flaggedQuestions = {};     // Set of question indices flagged as ragu-ragu
  bool _isSubmitting = false;
  late final DateTime _startTime;

  String _cleanHtml(String raw) {
    if (raw.isEmpty) return '';
    final RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    final String cleaned = raw.replaceAll(exp, '');
    return cleaned
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchQuestions();
    });
  }

  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cbtVm = Provider.of<CbtViewModel>(context, listen: false);
      final res = await cbtVm.getExamQuestions(widget.authToken, widget.jadwalId);
      final rawQuestions = (res['questions'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      setState(() {
        _examData = res;
        _questions = rawQuestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _submitExam() async {
    setState(() => _isSubmitting = true);

    try {
      final cbtVm = Provider.of<CbtViewModel>(context, listen: false);

      final List<Map<String, dynamic>> answersPayload = [];
      for (int i = 0; i < _questions.length; i++) {
        final q = _questions[i];
        final selectedOptionId = _selectedAnswers[i];
        answersPayload.add({
          'soal_id': q['id'],
          'jawaban_pilihan_id': selectedOptionId,
          'jawaban_text': null,
          'jenis_soal': q['jenis_soal'] ?? 'pilihan_ganda',
        });
      }

      final waktuMulaiStr = _startTime.toUtc().toIso8601String().split('.').first.replaceAll('T', ' ');

      final result = await cbtVm.submitExam(
        widget.authToken,
        widget.jadwalId,
        answersPayload,
        waktuMulaiStr,
      );

      if (mounted) {
        _showSuccessDialog(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim jawaban: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: primaryLightColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: primaryColor, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ujian Berhasil Diselesaikan!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkSlate),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Jawaban Anda telah berhasil disimpan ke sistem CBT.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundSlate,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total Soal', '${result['jumlah_soal'] ?? _questions.length}'),
                    _buildStatItem('Dijawab', '${result['jumlah_dijawab'] ?? _selectedAnswers.length}'),
                    _buildStatItem('Kosong', '${result['jumlah_tidak_dijawab'] ?? (_questions.length - _selectedAnswers.length)}'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close Dialog
                    Navigator.pop(context); // Back to CBT List View
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Selesai & Kembali',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  void _showQuestionGridSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Navigasi Soal Ujian',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkSlate),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildLegendItem(primaryColor, 'Sudah Dijawab'),
                      const SizedBox(width: 12),
                      _buildLegendItem(warningColor, 'Ragu-ragu'),
                      const SizedBox(width: 12),
                      _buildLegendItem(Colors.grey.shade300, 'Belum Dijawab'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _currentIndex;
                        final isAnswered = _selectedAnswers.containsKey(index);
                        final isFlagged = _flaggedQuestions.contains(index);

                        Color bgColor = Colors.grey.shade100;
                        Color textColor = darkSlate;

                        if (isFlagged) {
                          bgColor = warningColor;
                          textColor = Colors.white;
                        } else if (isAnswered) {
                          bgColor = primaryColor;
                          textColor = Colors.white;
                        }

                        return InkWell(
                          onTap: () {
                            setState(() => _currentIndex = index);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? darkSlate : Colors.transparent,
                                width: isSelected ? 2 : 0,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
      ],
    );
  }

  void _showSubmitConfirmation() {
    final unansweredCount = _questions.length - _selectedAnswers.length;
    final flaggedCount = _flaggedQuestions.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Selesaikan Ujian?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (unansweredCount > 0) ...[
              Text(
                '• Masih ada $unansweredCount soal yang belum dijawab.',
                style: const TextStyle(fontSize: 12, color: dangerColor, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
            ],
            if (flaggedCount > 0) ...[
              Text(
                '• Ada $flaggedCount soal yang ditandai Ragu-ragu.',
                style: const TextStyle(fontSize: 12, color: warningColor, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              'Apakah Anda yakin ingin menyelesaikan dan mengumpulkan jawaban ujian ini?',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Periksa Kembali', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    Navigator.pop(context);
                    _submitExam();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Ya, Selesaikan', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar Ujian?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          'Ujian sedang berlangsung. Jika keluar sekarang, Anda dapat melanjutkan selama rentang waktu ujian masih aktif.',
          style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Lanjutkan Ujian', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Keluar Ujian', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundSlate,
        appBar: SharedHeader(
          title: widget.subject,
          backgroundColor: Colors.white,
          foregroundColor: darkSlate,
          centerTitle: true,
          showBackButton: true,
          onBack: _showExitConfirmation,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              SizedBox(height: 16),
              Text('Memuat soal ujian...', style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _questions.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundSlate,
        appBar: SharedHeader(
          title: widget.subject,
          backgroundColor: Colors.white,
          foregroundColor: darkSlate,
          centerTitle: true,
          showBackButton: true,
          onBack: () => Navigator.pop(context),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: dangerColor, size: 48),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'Tidak ada soal ditemukan pada jadwal ujian ini.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: darkSlate),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _fetchQuestions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentQ = _questions[_currentIndex];
    final selectedOptionId = _selectedAnswers[_currentIndex];
    final isFlagged = _flaggedQuestions.contains(_currentIndex);
    final options = (currentQ['options'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return Scaffold(
      backgroundColor: backgroundSlate,
      appBar: SharedHeader(
        title: _examData?['judul_ujian'] ?? widget.subject,
        backgroundColor: Colors.white,
        foregroundColor: darkSlate,
        centerTitle: true,
        elevation: 0,
        showBackButton: true,
        onBack: _showExitConfirmation,
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, color: darkSlate, size: 20),
            tooltip: 'Navigasi Soal',
            onPressed: _showQuestionGridSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
              minHeight: 4,
            ),
            // Header Info Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Soal ${_currentIndex + 1} dari ${_questions.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: darkSlate),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isFlagged) {
                          _flaggedQuestions.remove(_currentIndex);
                        } else {
                          _flaggedQuestions.add(_currentIndex);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            isFlagged ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            size: 16,
                            color: isFlagged ? warningColor : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isFlagged ? 'Ragu-ragu' : 'Tandai Ragu',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isFlagged ? warningColor : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Question & Options Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: primaryLightColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'SOAL PILIHAN GANDA • BOBOT ${currentQ['bobot_nilai'] ?? 1.0}',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _cleanHtml(currentQ['pertanyaan'] ?? ''),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: darkSlate,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Pilih Jawaban:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    // Options List
                    ...options.map((opt) {
                      final optId = opt['id'] as int?;
                      final kode = opt['kode']?.toString() ?? '';
                      final textJawaban = _cleanHtml(opt['teks_jawaban']?.toString() ?? '');
                      final isSelected = selectedOptionId == optId;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedAnswers[_currentIndex] = optId!;
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryLightColor : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isSelected ? primaryColor : backgroundSlate,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? primaryColor : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      kode,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : darkSlate,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    textJawaban,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? primaryColor : darkSlate,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            // Bottom Action Navigation Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  if (_currentIndex > 0) ...[
                    OutlinedButton(
                      onPressed: () => setState(() => _currentIndex--),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Sebelumnya',
                        style: TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentIndex < _questions.length - 1) {
                          setState(() => _currentIndex++);
                        } else {
                          _showSubmitConfirmation();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentIndex == _questions.length - 1 ? 'Selesaikan Ujian' : 'Selanjutnya',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
