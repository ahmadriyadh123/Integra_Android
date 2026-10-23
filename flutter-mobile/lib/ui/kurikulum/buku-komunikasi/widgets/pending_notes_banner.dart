import 'package:flutter/material.dart';

class PendingNotesBanner extends StatelessWidget {
  final int pendingCount;
  final bool isSyncing;
  final VoidCallback onSync;

  const PendingNotesBanner({
    super.key,
    required this.pendingCount,
    required this.isSyncing,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFFFFF7ED), // amber-50
          border: Border(
            bottom: BorderSide(color: Color(0xFFFED7AA)), // amber-200
          ),
        ),
        child: Row(
          children: [
            isSyncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFF59E0B),
                    ),
                  )
                : const Icon(
                    Icons.cloud_upload_outlined,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isSyncing
                    ? 'Mengirim catatan tertunda...'
                    : '$pendingCount catatan menunggu koneksi internet.',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E), // amber-800
                ),
              ),
            ),
            if (!isSyncing)
              GestureDetector(
                onTap: onSync,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    'Kirim Sekarang',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF59E0B),
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
