import 'package:flutter/material.dart';

import '../../../../data/model/kurikulum/cbt/cbt_model.dart';

const _primary = Color(0xFF059669);
const _primaryLight = Color(0xFFECFDF5);
const _dark = Color(0xFF0F172A);
const _background = Color(0xFFF8FAFC);
const _warning = Color(0xFFF59E0B);
const _danger = Color(0xFFE11D48);

void showCbtSuccessDialog(
  BuildContext context, {
  required CbtSubmitResult result,
  required VoidCallback onDone,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: _primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: _primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ujian Berhasil Diselesaikan!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _dark,
              ),
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
                color: _background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem('Total Soal', '${result.totalQuestions}'),
                  _StatItem('Dijawab', '${result.answeredQuestions}'),
                  _StatItem('Kosong', '${result.unansweredQuestions}'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Selesai & Kembali',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void showCbtSubmitConfirmation(
  BuildContext context, {
  required int unansweredCount,
  required int flaggedCount,
  required bool isSubmitting,
  required VoidCallback onConfirm,
}) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Selesaikan Ujian?',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (unansweredCount > 0) ...[
            Text(
              '• Masih ada $unansweredCount soal yang belum dijawab.',
              style: const TextStyle(
                fontSize: 12,
                color: _danger,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (flaggedCount > 0) ...[
            Text(
              '• Ada $flaggedCount soal yang ditandai Ragu-ragu.',
              style: const TextStyle(
                fontSize: 12,
                color: _warning,
                fontWeight: FontWeight.w600,
              ),
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
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text(
            'Periksa Kembali',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        ElevatedButton(
          onPressed: isSubmitting
              ? null
              : () {
                  Navigator.pop(dialogContext);
                  onConfirm();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Ya, Selesaikan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

void showCbtExitConfirmation(
  BuildContext context, {
  required VoidCallback onExit,
}) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Keluar Ujian?',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: const Text(
        'Ujian sedang berlangsung. Jika keluar sekarang, Anda dapat melanjutkan selama rentang waktu ujian masih aktif.',
        style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text(
            'Lanjutkan Ujian',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        ElevatedButton(
          onPressed: onExit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _danger,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Keluar Ujian',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: _dark,
        ),
      ),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ],
  );
}
