import 'package:flutter/material.dart';

class DailyNoteCard extends StatelessWidget {
  final String day;
  final String date;
  final bool hasTeacherNote;
  final String? teacherNote;
  final TextEditingController responseController;
  final VoidCallback onSubmitResponse;

  const DailyNoteCard({
    super.key,
    required this.day,
    required this.date,
    required this.hasTeacherNote,
    this.teacherNote,
    required this.responseController,
    required this.onSubmitResponse,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF059669);
    const Color textSlate = Color(0xFF475569);
    final Color borderColor = hasTeacherNote ? primaryTeal : const Color(0xFFCBD5E1);
    final double cardOpacity = hasTeacherNote ? 1.0 : 0.85;

    return Opacity(
      opacity: cardOpacity,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: borderColor, width: 4)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(primaryTeal, textSlate),
                const SizedBox(height: 12),
                
                if (hasTeacherNote)
                  _buildTeacherNoteBox()
                else
                  _buildEmptyNoteBox(textSlate),
                  
                const SizedBox(height: 12),
                
                // Form Input Respons Orang Tua
                TextField(
                  controller: responseController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: hasTeacherNote
                        ? 'Tulis respons atau tanggapan orang tua untuk guru...'
                        : 'Tulis catatan opsional untuk guru...',
                    hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.all(12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: primaryTeal),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSubmitResponse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasTeacherNote ? primaryTeal : textSlate,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          hasTeacherNote ? 'Kirim Respons' : 'Simpan Catatan',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        if (hasTeacherNote) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, size: 14),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(Color primaryTeal, Color textSlate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              day,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              date,
              style: TextStyle(
                fontSize: 11,
                color: textSlate,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: hasTeacherNote ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasTeacherNote ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            hasTeacherNote ? 'Ada Catatan' : 'Tidak Ada Catatan',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: hasTeacherNote ? primaryTeal : textSlate,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherNoteBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        border: Border.all(color: const Color(0xFFA7F3D0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('👩‍🏫', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catatan Wali Kelas:',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '"$teacherNote"',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNoteBox(Color textSlate) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Tidak ada catatan khusus dari guru hari ini (-)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: textSlate,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}