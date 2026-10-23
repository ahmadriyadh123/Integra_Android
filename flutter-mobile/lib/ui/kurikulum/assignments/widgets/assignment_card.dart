import 'package:flutter/material.dart';

import '../../../../data/model/kurikulum/assignments/assignment_model.dart';

class AssignmentCard extends StatelessWidget {
  final AssignmentItem item;
  final VoidCallback onTap;

  const AssignmentCard({super.key, required this.item, required this.onTap});

  static const Color _primaryEmerald = Color(0xFF059669);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final attachments = item.studentSubmission?.attachments ?? [];
    final status = _assignmentStatus;
    final startedAt = _formatDateTime(item.issuedDate);
    final deadline = _formatDateTime(item.submissionDeadline);
    final marks = item.studentSubmission?.marks;
    final gradeText = item.isGraded && marks != null
        ? '${marks.toStringAsFixed(marks.truncateToDouble() == marks ? 0 : 1)} / ${item.maxMarks.toStringAsFixed(0)}'
        : 'Belum dinilai';
    final uploadText = attachments.isEmpty
        ? (item.isSubmitted ? 'Terkumpul' : 'Belum ada berkas')
        : attachments.length == 1
        ? attachments.first.fileName
        : '${attachments.length} berkas diunggah';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x080F172A),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildSubjectPill(item.subject.name)),
                      _buildStatusPill(status.$1, status.$2, status.$3),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      item.description.trim(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: _textMuted,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateInfo(
                          icon: Icons.play_circle_outline_rounded,
                          label: 'Mulai',
                          value: startedAt.isEmpty ? '-' : startedAt,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateInfo(
                          icon: Icons.event_outlined,
                          label: 'Deadline',
                          value: deadline.isEmpty ? 'Tanpa batas' : deadline,
                          valueColor: item.isOverdue
                              ? const Color(0xFFDC2626)
                              : _textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          attachments.isNotEmpty
                              ? Icons.attach_file_rounded
                              : Icons.upload_file_outlined,
                          size: 16,
                          color: attachments.isNotEmpty
                              ? _primaryEmerald
                              : _textMuted,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            uploadText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const SizedBox(
                          height: 20,
                          child: VerticalDivider(
                            width: 1,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          item.isGraded
                              ? Icons.grade_rounded
                              : Icons.workspace_premium_outlined,
                          size: 16,
                          color: item.isGraded ? _primaryEmerald : _textMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          gradeText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: item.isGraded ? _primaryEmerald : _textMuted,
                          ),
                        ),
                      ],
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

  Widget _buildSubjectPill(String subject) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFECFDF5),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.menu_book_rounded, size: 13, color: _primaryEmerald),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            subject,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _primaryEmerald,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildStatusPill(String label, Color color, Color background) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );

  Widget _buildDateInfo({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = _textDark,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 15, color: _textMuted),
      const SizedBox(width: 6),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: _textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: valueColor,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  (String, Color, Color) get _assignmentStatus {
    if (item.isGraded) {
      return ('Dinilai', const Color(0xFF047857), const Color(0xFFECFDF5));
    }
    if (item.isSubmitted) {
      return ('Terkumpul', const Color(0xFF0369A1), const Color(0xFFF0F9FF));
    }
    if (item.isOverdue) {
      return ('Terlambat', const Color(0xFFB91C1C), const Color(0xFFFEF2F2));
    }
    return (
      'Perlu dikumpulkan',
      const Color(0xFFB45309),
      const Color(0xFFFFFBEB),
    );
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '';
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
    final month = months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day $month ${date.year}, $hour:$minute';
  }
}
