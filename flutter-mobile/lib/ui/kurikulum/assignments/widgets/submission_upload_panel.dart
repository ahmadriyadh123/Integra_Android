import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class SubmissionUploadPanel extends StatelessWidget {
  final bool canEditSubmission;
  final bool isUploading;
  final bool hasChanges;
  final bool canSubmit;
  final List<PlatformFile> files;
  final VoidCallback onPickFiles;
  final ValueChanged<int> onRemoveFile;
  final VoidCallback onSubmit;

  const SubmissionUploadPanel({
    super.key,
    required this.canEditSubmission,
    required this.isUploading,
    required this.hasChanges,
    required this.canSubmit,
    required this.files,
    required this.onPickFiles,
    required this.onRemoveFile,
    required this.onSubmit,
  });

  static const _muted = Color(0xFF64748B);
  static const _green = Color(0xFF059669);

  @override
  Widget build(BuildContext context) => Container(
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
          canEditSubmission ? 'KELOLA BERKAS PENGUMPULAN' : 'PENGUMPULAN TUGAS',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _muted,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isUploading ? null : onPickFiles,
            icon: const Icon(Icons.attach_file_rounded),
            label: const Text('Tambah berkas'),
          ),
        ),
        if (hasChanges) ...[
          const SizedBox(height: 12),
          ...files.asMap().entries.map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.insert_drive_file_outlined,
                color: _green,
              ),
              title: Text(
                entry.value.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(_formatFileSize(entry.value.lengthSync() ?? 0)),
              trailing: IconButton(
                tooltip: 'Hapus berkas',
                onPressed: isUploading ? null : () => onRemoveFile(entry.key),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isUploading || !canSubmit ? null : onSubmit,
              icon: isUploading
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
                isUploading
                    ? 'Menyimpan perubahan...'
                    : canEditSubmission
                    ? 'Simpan perubahan'
                    : 'Submit berkas',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          canEditSubmission
              ? 'Tambahkan berkas atau tandai lampiran yang akan dihapus, lalu simpan perubahan. Minimal satu berkas harus tersisa. Maksimum 20 MiB per berkas.'
              : 'Pilih satu atau beberapa berkas terlebih dahulu, lalu tekan Submit. Maksimum 20 MiB per berkas.',
          style: const TextStyle(fontSize: 11, color: _muted),
        ),
      ],
    ),
  );

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KiB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
  }
}
