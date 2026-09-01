import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/shared_header.dart';
import 'models/assignment_model.dart';

class AssignmentDetailView extends StatelessWidget {
  final AssignmentItem assignment;
  final String authToken;

  const AssignmentDetailView({
    super.key,
    required this.assignment,
    required this.authToken,
  });

  static const Color primaryEmerald = Color(0xFF059669);
  static const Color bgSlate = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSlate,
      appBar: SharedHeader(
        title: 'DETAIL PENUGASAN',
        backgroundColor: Colors.white,
        foregroundColor: Colors.white,
        elevation: 0,
        showBackButton: true,
        onBack: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Card
            _buildHeaderCard(),
            const SizedBox(height: 20),

            // Status Pengumpulan Card
            _buildSubmissionStatusCard(),
            const SizedBox(height: 20),

            // Deskripsi / Petunjuk Tugas
            const Text(
              'PETUNJUK & DESKRIPSI',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: textMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                assignment.description.isNotEmpty
                    ? assignment.description
                    : 'Tidak ada petunjuk khusus untuk tugas ini.',
                style: const TextStyle(
                  fontSize: 13,
                  color: textDark,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Lampiran Tugas dari Guru
            if (assignment.teacherAttachments.isNotEmpty) ...[
              const Text(
                'LAMPIRAN TUGAS (GURU)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              ...assignment.teacherAttachments.map((att) => _buildAttachmentTile(att)),
              const SizedBox(height: 24),
            ],

            // Lampiran Pengumpulan dari Siswa
            if (assignment.studentSubmission?.attachments.isNotEmpty == true) ...[
              const Text(
                'LAMPIRAN PENGUMPULAN (SISWA)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              ...assignment.studentSubmission!.attachments.map((att) => _buildAttachmentTile(att)),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  assignment.assignmentType,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            assignment.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          _buildInfoRow(
            icon: Icons.event_note_rounded,
            label: 'Diberikan',
            value: _formatDate(assignment.issuedDate),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.alarm_rounded,
            label: 'Batas Waktu',
            value: _formatDate(assignment.submissionDeadline),
            isHighlight: assignment.isOverdue,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.grade_rounded,
            label: 'Nilai Maksimal',
            value: '${assignment.maxMarks.toStringAsFixed(0)} Poin',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isHighlight ? const Color(0xFFEF4444) : textMuted,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: textMuted),
        ),
        Text(
          value.isNotEmpty ? value : '-',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isHighlight ? const Color(0xFFEF4444) : textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionStatusCard() {
    final sub = assignment.studentSubmission;

    Color bgColor = const Color(0xFFFFFBEB);
    Color borderColor = const Color(0xFFFDE68A);
    Color textColor = const Color(0xFFD97706);
    IconData icon = Icons.pending_actions_rounded;
    String statusTitle = 'Perlu Dikumpulkan';
    String statusSubtitle = 'Silakan kumpulkan tugas Anda sebelum batas waktu.';

    if (assignment.isGraded) {
      bgColor = const Color(0xFFECFDF5);
      borderColor = const Color(0xFFA7F3D0);
      textColor = primaryEmerald;
      icon = Icons.stars_rounded;
      statusTitle = 'Sudah Dinilai';
      statusSubtitle = 'Nilai Anda: ${sub?.marks.toStringAsFixed(sub.marks.truncateToDouble() == sub.marks ? 0 : 1)} / ${assignment.maxMarks.toStringAsFixed(0)}';
    } else if (assignment.isSubmitted) {
      bgColor = const Color(0xFFF0F9FF);
      borderColor = const Color(0xFFBAE6FD);
      textColor = const Color(0xFF0284C7);
      icon = Icons.task_alt_rounded;
      statusTitle = 'Sudah Dikumpulkan';
      statusSubtitle = sub?.submittedAt != null
          ? 'Dikumpulkan pada ${_formatDate(sub!.submittedAt)}'
          : 'Tugas telah dikumpulkan dan menunggu penilaian guru.';
    } else if (assignment.isOverdue) {
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFCA5A5);
      textColor = const Color(0xFFDC2626);
      icon = Icons.warning_amber_rounded;
      statusTitle = 'Terlambat Mengumpulkan';
      statusSubtitle = 'Batas waktu penugasan telah lewat.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: textColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentTile(AttachmentItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.attach_file_rounded, color: primaryEmerald, size: 20),
        ),
        title: Text(
          item.fileName,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          item.uploadedByRole == 'teacher' ? 'Lampiran Guru' : 'Lampiran Siswa',
          style: const TextStyle(fontSize: 11, color: textMuted),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new_rounded, size: 18, color: primaryEmerald),
          onPressed: () async {
            if (item.fileUrl.isNotEmpty) {
              final uri = Uri.parse(item.fileUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute';
  }
}
