import 'package:flutter/material.dart';

import '../../../../data/model/kurikulum/cbt/cbt_model.dart';

const _primaryColor = Color(0xFF059669);
const _primaryLightColor = Color(0xFFECFDF5);
const _darkSlate = Color(0xFF0F172A);
const _backgroundSlate = Color(0xFFF8FAFC);
const _warningColor = Color(0xFFF59E0B);

class CbtExamProgressBar extends StatelessWidget {
  const CbtExamProgressBar({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
    required this.isFlagged,
    required this.onToggleFlag,
  });

  final int currentIndex;
  final int totalQuestions;
  final bool isFlagged;
  final VoidCallback onToggleFlag;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      LinearProgressIndicator(
        value: (currentIndex + 1) / totalQuestions,
        backgroundColor: const Color(0xFFE2E8F0),
        valueColor: const AlwaysStoppedAnimation<Color>(_primaryColor),
        minHeight: 4,
      ),
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Soal ${currentIndex + 1} dari $totalQuestions',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _darkSlate,
              ),
            ),
            InkWell(
              onTap: onToggleFlag,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      isFlagged
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 16,
                      color: isFlagged ? _warningColor : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isFlagged ? 'Ragu-ragu' : 'Tandai Ragu',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isFlagged ? _warningColor : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class CbtExamQuestionPanel extends StatelessWidget {
  const CbtExamQuestionPanel({
    super.key,
    required this.question,
    required this.selectedOptionId,
    required this.onSelectOption,
  });

  final CbtQuestion question;
  final int? selectedOptionId;
  final ValueChanged<int> onSelectOption;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
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
                  color: _primaryLightColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SOAL PILIHAN GANDA • BOBOT ${question.scoreWeight}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _cleanHtml(question.text),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _darkSlate,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Pilih Jawaban:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        ...question.options.map((option) {
          final isSelected = selectedOptionId == option.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => onSelectOption(option.id),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryLightColor : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? _primaryColor
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected ? _primaryColor : _backgroundSlate,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? _primaryColor
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          option.code,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : _darkSlate,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _cleanHtml(option.text),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? _primaryColor : _darkSlate,
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
  );
}

class CbtExamNavigationBar extends StatelessWidget {
  const CbtExamNavigationBar({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
    required this.onPrevious,
    required this.onContinue,
  });

  final int currentIndex;
  final int totalQuestions;
  final VoidCallback onPrevious;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Colors.grey.shade200)),
    ),
    child: Row(
      children: [
        if (currentIndex > 0) ...[
          OutlinedButton(
            onPressed: onPrevious,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Sebelumnya',
              style: TextStyle(
                color: Color(0xFF475569),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              currentIndex == totalQuestions - 1
                  ? 'Selesaikan Ujian'
                  : 'Selanjutnya',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

void showCbtQuestionGridSheet(
  BuildContext context, {
  required int questionCount,
  required int currentIndex,
  required Set<int> answeredIndexes,
  required Set<int> flaggedIndexes,
  required ValueChanged<int> onSelectQuestion,
}) {
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => Padding(
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
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _darkSlate,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _QuestionGridLegend(color: _primaryColor, label: 'Sudah Dijawab'),
              SizedBox(width: 12),
              _QuestionGridLegend(color: _warningColor, label: 'Ragu-ragu'),
              SizedBox(width: 12),
              _QuestionGridLegend(color: Color(0xFFD1D5DB), label: 'Belum Dijawab'),
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
              itemCount: questionCount,
              itemBuilder: (context, index) {
                final isSelected = index == currentIndex;
                final isAnswered = answeredIndexes.contains(index);
                final isFlagged = flaggedIndexes.contains(index);
                final backgroundColor = isFlagged
                    ? _warningColor
                    : isAnswered
                    ? _primaryColor
                    : Colors.grey.shade100;
                final textColor = isFlagged || isAnswered
                    ? Colors.white
                    : _darkSlate;

                return InkWell(
                  onTap: () {
                    onSelectQuestion(index);
                    Navigator.pop(sheetContext);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? _darkSlate : Colors.transparent,
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
    ),
  );
}

class _QuestionGridLegend extends StatelessWidget {
  const _QuestionGridLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
      ),
    ],
  );
}

String _cleanHtml(String raw) => raw
    .replaceAll(RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .trim();
