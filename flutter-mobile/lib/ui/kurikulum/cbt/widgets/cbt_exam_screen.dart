import 'package:flutter/material.dart';
import 'package:flutter_application_1/utils/user_friendly_error.dart';
import 'package:flutter_application_1/domain/models/cbt_answer.dart';
import 'package:provider/provider.dart';
import '../../../../data/model/kurikulum/cbt/cbt_model.dart';
import '../view_models/cbt_viewmodel.dart';
import '../../../core/ui/shared_header.dart';
import './cbt_exam_components.dart';
import './cbt_exam_dialogs.dart';

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
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color backgroundSlate = Color(0xFFF8FAFC);
  static const Color dangerColor = Color(0xFFE11D48);

  bool _isLoading = true;
  String? _errorMessage;
  CbtExamData? _examData;
  List<CbtQuestion> _questions = [];

  int _currentIndex = 0;
  final Map<int, int> _selectedAnswers = {}; // Map question index to option_id
  final Set<int> _flaggedQuestions =
      {}; // Set of question indices flagged as ragu-ragu
  bool _isSubmitting = false;
  late final DateTime _startTime;

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
      final examData = await cbtVm.getExamQuestions(
        widget.authToken,
        widget.jadwalId,
      );

      setState(() {
        _examData = examData;
        _questions = examData.questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = userFriendlyError(
          e,
          fallback: 'Soal ujian belum dapat dimuat. Silakan coba lagi.',
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _submitExam() async {
    setState(() => _isSubmitting = true);

    try {
      final cbtVm = Provider.of<CbtViewModel>(context, listen: false);

      final List<CbtAnswer> answersPayload = [];
      for (int i = 0; i < _questions.length; i++) {
        final q = _questions[i];
        final selectedOptionId = _selectedAnswers[i];
        answersPayload.add(
          CbtAnswer(
            questionId: q.id,
            selectedOptionId: selectedOptionId,
            questionType: q.type,
          ),
        );
      }

      final waktuMulaiStr = _startTime
          .toUtc()
          .toIso8601String()
          .split('.')
          .first
          .replaceAll('T', ' ');

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
            content: Text(
              'Jawaban belum dapat dikirim. ${userFriendlyError(e)}',
            ),
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

  void _showSuccessDialog(CbtSubmitResult result) {
    showCbtSuccessDialog(
      context,
      result: result,
      onDone: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );
  }

  void _showQuestionGridSheet() {
    showCbtQuestionGridSheet(
      context,
      questionCount: _questions.length,
      currentIndex: _currentIndex,
      answeredIndexes: _selectedAnswers.keys.toSet(),
      flaggedIndexes: _flaggedQuestions,
      onSelectQuestion: (index) => setState(() => _currentIndex = index),
    );
  }

  void _showSubmitConfirmation() {
    showCbtSubmitConfirmation(
      context,
      unansweredCount: _questions.length - _selectedAnswers.length,
      flaggedCount: _flaggedQuestions.length,
      isSubmitting: _isSubmitting,
      onConfirm: _submitExam,
    );
  }

  void _showExitConfirmation() {
    showCbtExitConfirmation(
      context,
      onExit: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String examTitle = _examData?.title.isNotEmpty == true
        ? _examData!.title
        : widget.subject;

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
              Text(
                'Memuat soal ujian...',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _questions.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundSlate,
        appBar: SharedHeader(
          title: examTitle,
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
                const Icon(
                  Icons.error_outline_rounded,
                  color: dangerColor,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ??
                      'Tidak ada soal ditemukan pada jadwal ujian ini.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: darkSlate),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _fetchQuestions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Coba Lagi',
                    style: TextStyle(color: Colors.white),
                  ),
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

    return Scaffold(
      backgroundColor: backgroundSlate,
      appBar: SharedHeader(
        title: _examData?.title.isNotEmpty == true
            ? _examData!.title
            : widget.subject,
        backgroundColor: Colors.white,
        foregroundColor: darkSlate,
        centerTitle: true,
        elevation: 0,
        showBackButton: true,
        onBack: _showExitConfirmation,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.grid_view_rounded,
              color: darkSlate,
              size: 20,
            ),
            tooltip: 'Navigasi Soal',
            onPressed: _showQuestionGridSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            CbtExamProgressBar(
              currentIndex: _currentIndex,
              totalQuestions: _questions.length,
              isFlagged: isFlagged,
              onToggleFlag: () => setState(() {
                if (isFlagged) {
                  _flaggedQuestions.remove(_currentIndex);
                } else {
                  _flaggedQuestions.add(_currentIndex);
                }
              }),
            ),
            Expanded(
              child: CbtExamQuestionPanel(
                question: currentQ,
                selectedOptionId: selectedOptionId,
                onSelectOption: (optionId) =>
                    setState(() => _selectedAnswers[_currentIndex] = optionId),
              ),
            ),
            CbtExamNavigationBar(
              currentIndex: _currentIndex,
              totalQuestions: _questions.length,
              onPrevious: () => setState(() => _currentIndex--),
              onContinue: () {
                if (_currentIndex < _questions.length - 1) {
                  setState(() => _currentIndex++);
                } else {
                  _showSubmitConfirmation();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
