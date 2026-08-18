import 'package:flutter/material.dart';
import 'widgets/quiz/quiz_top_bar.dart';
import 'widgets/quiz/quiz_option_card.dart';
import 'widgets/quiz/quiz_result_card.dart';

class QuizView extends StatefulWidget {
  final String title;
  final String subject;

  const QuizView({
    super.key,
    this.title = 'Kuis Akhir Bab 2: Aturan Sinus & Cosinus',
    this.subject = 'Matematika Wajib',
  });

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  static const Color primaryColor = Color(0xFF059669);
  static const Color primaryLightColor = Color(0xFFECFDF5);
  static const Color warningColor = Color(0xFFF59E0B);

  int _currentIndex = 0;
  bool _isSubmitted = false;
  final Map<int, int> _selectedAnswers = {};
  final Set<int> _flaggedQuestions = {};

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Pada ΔABC, diketahui sudut A = 30°, sudut B = 45°, dan panjang sisi a = 8 cm. Berapakah panjang sisi b?',
      'options': ['4√2 cm', '8√2 cm', '16√2 cm', '8 cm'],
      'correctIndex': 1,
      'explanation': 'Menggunakan Aturan Sinus:\nb / sin(B) = a / sin(A)\nb / sin(45°) = 8 / sin(30°)\nb = 8√2 cm.',
    },
    {
      'question': 'Aturan Sinus berlaku untuk jenis segitiga apa saja?',
      'options': [
        'Hanya segitiga siku-siku',
        'Hanya segitiga sama sisi',
        'Semua jenis segitiga sembarang',
        'Hanya segitiga sama kaki'
      ],
      'correctIndex': 2,
      'explanation': 'Aturan Sinus dapat diterapkan pada semua jenis segitiga sembarang.',
    },
    // Soal-soal lainnya dapat Anda tambahkan di sini sesuai data asli...
  ];

  int get _calculatedScore {
    int scoreCount = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i]['correctIndex']) scoreCount += 20;
    }
    return scoreCount;
  }

  int get _correctAnswersCount {
    int count = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i]['correctIndex']) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: QuizTopBar(
        subject: widget.subject,
        title: widget.title,
        isSubmitted: _isSubmitted,
        onExitTap: _showExitConfirmation,
      ),
      body: SafeArea(
        child: _isSubmitted ? _buildResultSummaryView() : _buildQuizQuestionView(),
      ),
    );
  }

  Widget _buildQuizQuestionView() {
    final currentQ = _questions[_currentIndex];
    final selectedOption = _selectedAnswers[_currentIndex];
    final isFlagged = _flaggedQuestions.contains(_currentIndex);

    return Column(
      children: [
        LinearProgressIndicator(
          value: (_currentIndex + 1) / _questions.length,
          backgroundColor: const Color(0xFFE2E8F0),
          valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
          minHeight: 4,
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soal ${_currentIndex + 1} dari ${_questions.length}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryLightColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PILIHAN GANDA',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currentQ['question'],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Pilih Jawaban yang Benar:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ...List.generate(
                  (currentQ['options'] as List).length,
                  (optionIndex) {
                    final optionText = currentQ['options'][optionIndex];
                    final optionLabel = String.fromCharCode(65 + optionIndex);
                    return QuizOptionCard(
                      optionText: optionText,
                      optionLabel: optionLabel,
                      isSelected: selectedOption == optionIndex,
                      onTap: () => setState(() => _selectedAnswers[_currentIndex] = optionIndex),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
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
              child: const Text('Sebelumnya', style: TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.bold)),
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
                _currentIndex == _questions.length - 1 ? 'Selesaikan Kuis' : 'Selanjutnya',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSummaryView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          QuizResultCard(
            score: _calculatedScore,
            isPassed: _calculatedScore >= 70,
            correctAnswersCount: _correctAnswersCount,
            totalQuestions: _questions.length,
            answeredCount: _selectedAnswers.length,
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Icon(Icons.assignment_turned_in_rounded, size: 18, color: primaryColor),
              SizedBox(width: 8),
              Text('Pembahasan & Kunci Jawaban', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              final q = _questions[index];
              final userAns = _selectedAnswers[index];
              final correctAns = q['correctIndex'];
              final isCorrect = userAns == correctAns;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: isCorrect ? primaryColor : const Color(0xFFE11D48),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${index + 1}. ${q['question']}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jawaban Anda: ${userAns != null ? q['options'][userAns] : "Tidak dijawab"}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isCorrect ? primaryColor : const Color(0xFFE11D48),
                            ),
                          ),
                          if (!isCorrect) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Kunci Jawaban: ${q['options'][correctAns]}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            'Pembahasan:\n${q['explanation']}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Kembali ke Modul Pelajaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmitConfirmation() {
    final unanswered = _questions.length - _selectedAnswers.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Selesaikan Kuis?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Text(
          unanswered > 0
              ? 'Masih ada $unanswered soal yang belum Anda jawab. Yakin ingin mengumpulkan?'
              : 'Anda telah menjawab semua soal. Kirim jawaban Anda sekarang?',
          style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Periksa Lagi', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isSubmitted = true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Kumpulkan', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
        title: const Text('Keluar dari Kuis?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Text(
          'Progres jawaban kuis saat ini tidak akan disimpan jika Anda keluar sekarang.',
          style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Ya, Keluar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}