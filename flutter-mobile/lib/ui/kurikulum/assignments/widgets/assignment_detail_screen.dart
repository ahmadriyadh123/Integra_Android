import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/utils/user_friendly_error.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/shared_header.dart';
import '../../../e-rapor/widgets/pdf_viewer_page.dart';
import '../../../../data/model/kurikulum/assignments/assignment_model.dart';
import '../../../../data/services/kurikulum/assignments/assignment_file_service.dart';
import '../../../../data/services/kurikulum/assignments/assignment_service.dart';
import '../view_models/assignment_viewmodel.dart';
import './assignment_attachment_tile.dart';
import './assignment_summary_cards.dart';
import './submission_upload_panel.dart';

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
  final AssignmentFileService _fileService = AssignmentFileService();
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
            AssignmentHeaderCard(assignment: assignment),
            const SizedBox(height: 20),

            // Status Pengumpulan Card
            AssignmentSubmissionStatusCard(assignment: assignment),
            const SizedBox(height: 20),

            if (assignment.canManageSubmission) ...[
              SubmissionUploadPanel(
                canEditSubmission: assignment.canEditSubmission,
                isUploading: _isUploading,
                hasChanges:
                    _pendingFiles.isNotEmpty ||
                    _removedAttachmentIds.isNotEmpty,
                canSubmit: _hasValidPendingChanges,
                files: _pendingFiles,
                onPickFiles: _pickFiles,
                onRemoveFile: (index) =>
                    setState(() => _pendingFiles.removeAt(index)),
                onSubmit: _submitFiles,
              ),
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
            AssignmentDescriptionCard(description: assignment.description),
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

  Future<void> _pickFiles() async {
    try {
      final selectedFiles = await _fileService.pickFiles();
      if (!mounted) return;
      if (selectedFiles.isEmpty) return;

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

  Future<void> _submitFiles() async {
    final viewModel = context.read<AssignmentViewModel>();
    try {
      setState(() => _isUploading = true);
      final files = await _fileService.prepareUploads(_pendingFiles);
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

  Widget _buildAttachmentTile(AttachmentItem item, {bool removable = false}) {
    final isMarkedForRemoval = _removedAttachmentIds.contains(item.id);
    return AssignmentAttachmentTile(
      attachment: item,
      isOpening: _openingAttachmentIds.contains(item.id),
      isMarkedForRemoval: isMarkedForRemoval,
      canRemove: removable,
      isBusy: _isUploading,
      onOpen: () => _openAttachment(item),
      onToggleRemoval: () {
        setState(() {
          if (isMarkedForRemoval) {
            _removedAttachmentIds.remove(item.id);
          } else {
            _removedAttachmentIds.add(item.id);
          }
        });
      },
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
}
