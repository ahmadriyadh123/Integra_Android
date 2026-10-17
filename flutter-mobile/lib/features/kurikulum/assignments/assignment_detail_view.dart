import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/user_friendly_error.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../widgets/shared_header.dart';
import '../../e-rapor/widgets/pdf_viewer_page.dart';
import 'models/assignment_model.dart';
import 'services/assignment_service.dart';
import 'viewmodel/assignment_viewmodel.dart';

class AssignmentDetailView extends StatefulWidget {
  final AssignmentItem assignment;
  final String authToken;

  const AssignmentDetailView({
    super.key,
    required this.assignment,
    required this.authToken,
  });

  @override
  State<AssignmentDetailView> createState() => _AssignmentDetailViewState();
}

class _AssignmentDetailViewState extends State<AssignmentDetailView> {
  static const int _maxFileSize = 20 * 1024 * 1024;
  late AssignmentItem _assignment;
  bool _isUploading = false;
  final List<PlatformFile> _pendingFiles = [];
  final Set<int> _removedAttachmentIds = {};
  final Set<int> _openingAttachmentIds = {};

  AssignmentItem get assignment => _assignment;
  bool get _hasValidPendingChanges {
    final currentAttachmentCount =
        assignment.studentSubmission?.attachments.length ?? 0;
    final remainingCount =
        currentAttachmentCount -
        _removedAttachmentIds.length +
        _pendingFiles.length;
    return (_pendingFiles.isNotEmpty || _removedAttachmentIds.isNotEmpty) &&
        remainingCount > 0;
  }

  @override
  void initState() {
    super.initState();
    _assignment = widget.assignment;
  }

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
        foregroundColor: textDark,
        elevation: 0,
        showBackButton: true,
        onBack: () => Navigator.pop(context),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
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

            if (assignment.canManageSubmission) ...[
              _buildUploadCard(),
              const SizedBox(height: 20),
            ],

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
              ...assignment.teacherAttachments.map(
                (att) => _buildAttachmentTile(att),
              ),
              const SizedBox(height: 24),
            ],

            // Lampiran Pengumpulan dari Siswa
            if (assignment.studentSubmission?.attachments.isNotEmpty ==
                true) ...[
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
              ...assignment.studentSubmission!.attachments.map(
                (att) => _buildAttachmentTile(
                  att,
                  removable: assignment.canEditSubmission,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1FAE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            assignment.canEditSubmission
                ? 'KELOLA BERKAS PENGUMPULAN'
                : 'PENGUMPULAN TUGAS',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickFiles,
              icon: const Icon(Icons.attach_file_rounded),
              label: const Text('Tambah berkas'),
            ),
          ),
          if (_pendingFiles.isNotEmpty || _removedAttachmentIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._pendingFiles.asMap().entries.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.insert_drive_file_outlined,
                  color: primaryEmerald,
                ),
                title: Text(
                  entry.value.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(_formatFileSize(entry.value.lengthSync() ?? 0)),
                trailing: IconButton(
                  tooltip: 'Hapus berkas',
                  onPressed: _isUploading
                      ? null
                      : () => setState(() => _pendingFiles.removeAt(entry.key)),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isUploading || !_hasValidPendingChanges
                    ? null
                    : _submitFiles,
                icon: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isUploading
                      ? 'Menyimpan perubahan...'
                      : assignment.canEditSubmission
                      ? 'Simpan perubahan'
                      : 'Submit berkas',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryEmerald,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            assignment.canEditSubmission
                ? 'Tambahkan berkas atau tandai lampiran yang akan dihapus, lalu simpan perubahan. Minimal satu berkas harus tersisa. Maksimum 20 MiB per berkas.'
                : 'Pilih satu atau beberapa berkas terlebih dahulu, lalu tekan Submit. Maksimum 20 MiB per berkas.',
            style: const TextStyle(fontSize: 11, color: textMuted),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.any);
      if (!mounted) return;
      final selectedFiles = result ?? [];
      if (selectedFiles.isEmpty) return;

      final oversizedFile = selectedFiles
          .where((file) => (file.lengthSync() ?? 0) > _maxFileSize)
          .firstOrNull;
      if (oversizedFile != null) {
        throw Exception('${oversizedFile.name} melebihi batas ukuran 20 MiB.');
      }

      setState(() {
        _pendingFiles.addAll(selectedFiles);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFriendlyError(
              error,
              fallback: 'Berkas belum dapat dipilih. Silakan coba lagi.',
            ),
          ),
        ),
      );
    }
  }

  Future<AssignmentFileUpload> _prepareUpload(PlatformFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('${file.name} kosong atau tidak dapat dibaca.');
    }
    if (bytes.length > _maxFileSize) {
      throw Exception('${file.name} melebihi batas ukuran 20 MiB.');
    }
    return AssignmentFileUpload(
      stream: Stream<List<int>>.value(bytes),
      size: bytes.length,
      fileName: file.name,
    );
  }

  Future<void> _submitFiles() async {
    final viewModel = context.read<AssignmentViewModel>();
    try {
      setState(() => _isUploading = true);
      final files = <AssignmentFileUpload>[];
      for (final file in _pendingFiles) {
        files.add(await _prepareUpload(file));
      }
      if (!mounted) return;

      final updatedAssignment = assignment.canEditSubmission
          ? await viewModel.updateSubmissionAttachments(
              token: widget.authToken,
              assignment: assignment,
              files: files,
              removeAttachmentIds: _removedAttachmentIds.toList(),
            )
          : await viewModel.submitAssignment(
              token: widget.authToken,
              assignment: assignment,
              files: files,
            );
      await viewModel.fetchAssignments(widget.authToken, forceRefresh: true);
      if (!mounted) return;

      final synchronizedAssignment = viewModel.items
          .where((item) => item.id == assignment.id)
          .firstOrNull;
      setState(() {
        _assignment = synchronizedAssignment ?? updatedAssignment;
        _pendingFiles.clear();
        _removedAttachmentIds.clear();
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            assignment.canEditSubmission
                ? 'Perubahan berkas pengumpulan berhasil disimpan.'
                : '${files.length} berkas berhasil dikumpulkan.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      if (error is AssignmentAlreadySubmittedException) {
        await viewModel.fetchAssignments(widget.authToken, forceRefresh: true);
        if (!mounted) return;

        final refreshed = viewModel.items
            .where((item) => item.id == _assignment.id)
            .firstOrNull;

        setState(() {
          if (refreshed != null) _assignment = refreshed;
          _pendingFiles.clear();
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tugas sudah terkumpul. Status terbaru dimuat.'),
          ),
        );
        return;
      }

      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFriendlyError(
              error,
              fallback: 'Jawaban tugas belum dapat dikirim. Silakan coba lagi.',
            ),
          ),
        ),
      );
    }
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KiB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
            icon: Icons.alarm_rounded,
            label: 'Batas Waktu',
            value: _formatDate(assignment.submissionDeadline),
            isHighlight: assignment.isOverdue,
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
      statusSubtitle =
          'Nilai Anda: ${sub?.marks.toStringAsFixed(sub.marks.truncateToDouble() == sub.marks ? 0 : 1)} / ${assignment.maxMarks.toStringAsFixed(0)}';
    } else if (assignment.needsSubmissionFile) {
      bgColor = assignment.isOverdue
          ? const Color(0xFFFEF2F2)
          : const Color(0xFFFFFBEB);
      borderColor = assignment.isOverdue
          ? const Color(0xFFFCA5A5)
          : const Color(0xFFFDE68A);
      textColor = assignment.isOverdue
          ? const Color(0xFFDC2626)
          : const Color(0xFFD97706);
      icon = assignment.isOverdue
          ? Icons.warning_amber_rounded
          : Icons.upload_file_rounded;
      statusTitle = assignment.isOverdue
          ? 'Berkas belum dikumpulkan'
          : 'Berkas belum tersedia';
      statusSubtitle = assignment.isOverdue
          ? 'Status submission tercatat, tetapi file tidak ditemukan dan deadline sudah lewat.'
          : 'Status submission tercatat, tetapi file belum tersimpan. Unggah berkas sebelum batas waktu.';
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

  Widget _buildAttachmentTile(AttachmentItem item, {bool removable = false}) {
    final isOpening = _openingAttachmentIds.contains(item.id);
    final isMarkedForRemoval = _removedAttachmentIds.contains(item.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMarkedForRemoval
              ? const Color(0xFFFCA5A5)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.attach_file_rounded,
            color: primaryEmerald,
            size: 20,
          ),
        ),
        title: Text(
          item.fileName,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isMarkedForRemoval ? const Color(0xFFDC2626) : textDark,
            decoration: isMarkedForRemoval
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          item.uploadedByRole == 'teacher' ? 'Lampiran Guru' : 'Lampiran Siswa',
          style: const TextStyle(fontSize: 11, color: textMuted),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Buka lampiran',
              icon: isOpening
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: primaryEmerald,
                    ),
              onPressed: isOpening ? null : () => _openAttachment(item),
            ),
            if (removable)
              IconButton(
                tooltip: isMarkedForRemoval
                    ? 'Batalkan penghapusan'
                    : 'Tandai untuk dihapus',
                icon: Icon(
                  isMarkedForRemoval
                      ? Icons.undo_rounded
                      : Icons.delete_outline_rounded,
                  size: 20,
                  color: isMarkedForRemoval
                      ? primaryEmerald
                      : const Color(0xFFDC2626),
                ),
                onPressed: _isUploading
                    ? null
                    : () {
                        setState(() {
                          if (isMarkedForRemoval) {
                            _removedAttachmentIds.remove(item.id);
                          } else {
                            _removedAttachmentIds.add(item.id);
                          }
                        });
                      },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAttachment(AttachmentItem item) async {
    // 1. Simpan referensi viewModel di awal sebelum 'await'
    final viewModel = context.read<AssignmentViewModel>();

    setState(() => _openingAttachmentIds.add(item.id));
    try {
      final service = viewModel.repository.apiService;
      final uri = service.attachmentUri(item.fileUrl);

      if (item.fileName.toLowerCase().endsWith('.pdf')) {
        if (!mounted) return;
        final title = item.fileName.replaceFirst(
          RegExp(r'\.pdf$', caseSensitive: false),
          '',
        );
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PdfViewerPage(
              pdfUrl: uri.toString(),
              title: title,
              authToken: widget.authToken,
            ),
          ),
        );
        return;
      }

      final response = await service.downloadAttachment(
        token: widget.authToken,
        fileUrl: item.fileUrl,
      );

      if (response.bodyBytes.isEmpty) {
        throw Exception('Lampiran kosong atau tidak dapat dibaca.');
      }

      final directory = await getTemporaryDirectory();
      final safeName = item.fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final file = File(
        '${directory.path}/assignment_${assignment.id}_${item.id}_$safeName',
      );
      await file.writeAsBytes(response.bodyBytes, flush: true);

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        throw Exception(result.message);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFriendlyError(
              error,
              fallback: 'Lampiran belum dapat dibuka. Silakan coba lagi.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _openingAttachmentIds.remove(item.id));
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final months = [
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
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute';
  }
}
