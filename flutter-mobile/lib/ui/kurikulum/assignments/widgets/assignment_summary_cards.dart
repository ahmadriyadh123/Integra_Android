import 'package:flutter/material.dart';

import '../../../../data/model/kurikulum/assignments/assignment_model.dart';

class AssignmentHeaderCard extends StatelessWidget {
  final AssignmentItem assignment;

  const AssignmentHeaderCard({super.key, required this.assignment});

  static const _dark = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              assignment.subject.name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD97706),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            assignment.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _dark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.alarm_rounded,
                size: 16,
                color: assignment.isOverdue ? const Color(0xFFEF4444) : _muted,
              ),
              const SizedBox(width: 8),
              const Text(
                'Batas Waktu: ',
                style: TextStyle(fontSize: 12, color: _muted),
              ),
              Text(
                _formatDate(assignment.submissionDeadline),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: assignment.isOverdue ? const Color(0xFFEF4444) : _dark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day ${months[date.month - 1]} ${date.year}, $hour:$minute';
  }
}

class AssignmentSubmissionStatusCard extends StatelessWidget {
  final AssignmentItem assignment;

  const AssignmentSubmissionStatusCard({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    final submission = assignment.studentSubmission;
    var background = const Color(0xFFFFFBEB);
    var border = const Color(0xFFFDE68A);
    var foreground = const Color(0xFFD97706);
    var icon = Icons.pending_actions_rounded;
    var title = 'Perlu Dikumpulkan';
    var subtitle = 'Silakan kumpulkan tugas Anda sebelum batas waktu.';

    if (assignment.isGraded) {
      background = const Color(0xFFECFDF5);
      border = const Color(0xFFA7F3D0);
      foreground = const Color(0xFF059669);
      icon = Icons.stars_rounded;
      title = 'Sudah Dinilai';
      final marks = submission?.marks;
      subtitle = marks == null
          ? 'Tugas sudah dinilai.'
          : 'Nilai Anda: ${marks.toStringAsFixed(marks.truncateToDouble() == marks ? 0 : 1)} / ${assignment.maxMarks.toStringAsFixed(0)}';
    } else if (assignment.needsSubmissionFile) {
      background = assignment.isOverdue
          ? const Color(0xFFFEF2F2)
          : const Color(0xFFFFFBEB);
      border = assignment.isOverdue
          ? const Color(0xFFFCA5A5)
          : const Color(0xFFFDE68A);
      foreground = assignment.isOverdue
          ? const Color(0xFFDC2626)
          : const Color(0xFFD97706);
      icon = assignment.isOverdue
          ? Icons.warning_amber_rounded
          : Icons.upload_file_rounded;
      title = assignment.isOverdue
          ? 'Berkas belum dikumpulkan'
          : 'Berkas belum tersedia';
      subtitle = assignment.isOverdue
          ? 'Status submission tercatat, tetapi file tidak ditemukan dan deadline sudah lewat.'
          : 'Status submission tercatat, tetapi file belum tersimpan. Unggah berkas sebelum batas waktu.';
    } else if (assignment.isSubmitted) {
      background = const Color(0xFFF0F9FF);
      border = const Color(0xFFBAE6FD);
      foreground = const Color(0xFF0284C7);
      icon = Icons.task_alt_rounded;
      title = 'Sudah Dikumpulkan';
      final submittedAt = submission?.submittedAt;
      subtitle = submittedAt == null
          ? 'Tugas telah dikumpulkan dan menunggu penilaian guru.'
          : 'Dikumpulkan pada ${AssignmentHeaderCard._formatDate(submittedAt)}';
    } else if (assignment.isOverdue) {
      background = const Color(0xFFFEF2F2);
      border = const Color(0xFFFCA5A5);
      foreground = const Color(0xFFDC2626);
      icon = Icons.warning_amber_rounded;
      title = 'Terlambat Mengumpulkan';
      subtitle = 'Batas waktu penugasan telah lewat.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: foreground.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AssignmentDescriptionCard extends StatelessWidget {
  final String description;

  const AssignmentDescriptionCard({super.key, required this.description});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Text(
      description.trim().isEmpty
          ? 'Tidak ada petunjuk khusus untuk tugas ini.'
          : description,
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF1E293B),
        height: 1.5,
      ),
    ),
  );
}
