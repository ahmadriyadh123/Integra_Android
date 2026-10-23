import 'package:flutter/material.dart';

import '../../../../data/model/kurikulum/assignments/assignment_model.dart';

class AssignmentAttachmentTile extends StatelessWidget {
  final AttachmentItem attachment;
  final bool isOpening;
  final bool isMarkedForRemoval;
  final bool canRemove;
  final bool isBusy;
  final VoidCallback onOpen;
  final VoidCallback onToggleRemoval;

  const AssignmentAttachmentTile({
    super.key,
    required this.attachment,
    required this.isOpening,
    required this.isMarkedForRemoval,
    required this.canRemove,
    required this.isBusy,
    required this.onOpen,
    required this.onToggleRemoval,
  });

  static const _green = Color(0xFF059669);
  static const _dark = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) => Container(
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
        child: const Icon(Icons.attach_file_rounded, color: _green, size: 20),
      ),
      title: Text(
        attachment.fileName,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isMarkedForRemoval ? const Color(0xFFDC2626) : _dark,
          decoration: isMarkedForRemoval
              ? TextDecoration.lineThrough
              : TextDecoration.none,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        attachment.uploadedByRole == 'teacher'
            ? 'Lampiran Guru'
            : 'Lampiran Siswa',
        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
                    color: _green,
                  ),
            onPressed: isOpening ? null : onOpen,
          ),
          if (canRemove)
            IconButton(
              tooltip: isMarkedForRemoval
                  ? 'Batalkan penghapusan'
                  : 'Tandai untuk dihapus',
              icon: Icon(
                isMarkedForRemoval
                    ? Icons.undo_rounded
                    : Icons.delete_outline_rounded,
                size: 20,
                color: isMarkedForRemoval ? _green : const Color(0xFFDC2626),
              ),
              onPressed: isBusy ? null : onToggleRemoval,
            ),
        ],
      ),
    ),
  );
}
