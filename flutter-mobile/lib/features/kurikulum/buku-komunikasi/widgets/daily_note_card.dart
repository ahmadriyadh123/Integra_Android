import 'package:flutter/material.dart';

class DailyNoteCard extends StatefulWidget {
  final String day;
  final String date;
  final String? savedNote;
  final String? teacherFeedback;
  final TextEditingController noteController;
  final VoidCallback onSubmitNote;
  final bool isReadOnly;
  final bool noLineRecord;

  const DailyNoteCard({
    super.key,
    required this.day,
    required this.date,
    this.savedNote,
    this.teacherFeedback, 
    required this.noteController,
    required this.onSubmitNote,
    this.isReadOnly = false,
    this.noLineRecord = false,
  });

  @override
  State<DailyNoteCard> createState() => _DailyNoteCardState();
}

class _DailyNoteCardState extends State<DailyNoteCard> {
  bool _isEditing = false;

  static const Color primaryTeal = Color(0xFF059669);
  static const Color textSlate = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color bgSlate = Color(0xFFF8FAFC);
  static const Color borderColor = Color(0xFFE2E8F0);

  bool get hasUserNote =>
      widget.savedNote != null &&
      widget.savedNote!.isNotEmpty &&
      widget.savedNote != '-';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildContentSection(),
            if (widget.isReadOnly) _buildLockedBadge(),
            _buildTeacherFeedback(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              widget.day,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: darkSlate,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.date,
              style: const TextStyle(fontSize: 11, color: textSlate),
            ),
          ],
        ),
        _buildBadge(),
      ],
    );
  }

  Widget _buildBadge() {
    if (widget.isReadOnly) {
      return _badge('Terkunci', textMuted, const Color(0xFFF1F5F9), borderColor);
    }
    return _badge(
      hasUserNote ? 'Terkirim' : 'Belum Dikirim',
      hasUserNote ? primaryTeal : textSlate,
      hasUserNote ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
      hasUserNote ? const Color(0xFFA7F3D0) : borderColor,
    );
  }

  Widget _badge(String label, Color textColor, Color bgColor, Color borderClr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderClr),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    if (hasUserNote && !_isEditing) {
      return _savedNoteView();
    }
    return _inputForm();
  }

  Widget _inputForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catatan Harian Siswa:',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textSlate),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: widget.noteController,
          maxLines: 3,
          style: const TextStyle(fontSize: 12, color: darkSlate),
          decoration: InputDecoration(
            hintText: 'Tulis catatan harian Anda di sini...',
            hintStyle: const TextStyle(fontSize: 11, color: textMuted),
            filled: true,
            fillColor: bgSlate,
            contentPadding: const EdgeInsets.all(12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryTeal, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onSubmitNote,
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Kirim Catatan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _savedNoteView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        border: Border.all(color: const Color(0xFF99F6E4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Catatan Harian Terkirim:',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
              ),
              InkWell(
                onTap: () => setState(() => _isEditing = true),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 11, color: primaryTeal),
                      SizedBox(width: 3),
                      Text('Edit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: primaryTeal)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.savedNote!,
            style: const TextStyle(fontSize: 12, color: darkSlate, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasUserNote ? const Color(0xFFF0FDFA) : bgSlate,
        border: Border.all(color: hasUserNote ? const Color(0xFF99F6E4) : borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catatan Harian Siswa:',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textSlate),
          ),
          const SizedBox(height: 2),
          Text(
            hasUserNote ? widget.savedNote! : '(Belum ada catatan)',
            style: TextStyle(
              fontSize: 12,
              color: hasUserNote ? darkSlate : textMuted,
              fontStyle: hasUserNote ? FontStyle.normal : FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedBadge() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 12, color: textMuted),
            SizedBox(width: 4),
            Text(
              'Sudah dikirim - tidak dapat diubah',
              style: TextStyle(fontSize: 10, color: textMuted),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTeacherFeedback() {
  if (widget.teacherFeedback == null || widget.teacherFeedback == '-') {
    return const SizedBox.shrink();
  }
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF3C7), // Warna latar kuning lembut untuk catatan guru
      border: Border.all(color: const Color(0xFFFDE68A)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catatan/Feedback Guru:',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
        ),
        const SizedBox(height: 2),
        Text(
          widget.teacherFeedback!,
          style: const TextStyle(fontSize: 11, color: darkSlate, height: 1.3),
        ),
      ],
    ),
  );
}
}