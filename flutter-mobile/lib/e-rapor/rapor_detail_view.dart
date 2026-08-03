import 'package:flutter/material.dart';

class RaporDetailViewPage extends StatelessWidget {
  const RaporDetailViewPage({super.key});

  static const Color primaryTeal = Color(0xFF059669);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color backgroundSlate = Color(0xFFF8FAFC);
  static const Color textSlate = Color(0xFF475569);
  static const Color borderSlate = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundSlate,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildMetadataCard(),
            const SizedBox(height: 16),
            _buildPdfViewerSimulation(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: darkSlate, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'DETAIL E-RAPOR DIKNAS',
        style: TextStyle(color: darkSlate, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.download_rounded, color: primaryTeal, size: 22),
          onPressed: () {},
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: borderSlate, height: 1),
      ),
    );
  }

  Widget _buildMetadataCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSlate),
      ),
      child: Column(
        children: [
          _buildMetaRow(Icons.person, 'Nama Siswa', 'John Doe (12A)'),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildMetaRow(Icons.school, 'Kelas', 'Kelas 1 SD'),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildMetaRow(Icons.description, 'Semester', 'Semester 1', badgeColor: const Color(0xFFEFF6FF), badgeTextColor: const Color(0xFF1E40AF)),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildMetaRow(Icons.calendar_today, 'Tahun Ajaran', '2025/2026'),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildMetaRow(Icons.verified_user, 'Status Dokumen', 'Telah Ditandatangani', badgeColor: const Color(0xFFECFDF5), badgeTextColor: primaryTeal),
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value, {Color? badgeColor, Color? badgeTextColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: primaryTeal),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSlate)),
            ],
          ),
          if (badgeColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(20)),
              child: Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: badgeTextColor)),
            )
          else
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: darkSlate)),
        ],
      ),
    );
  }

  // Simulasi UI PDF Viewer dengan Toolbar
  Widget _buildPdfViewerSimulation() {
    return Container(
      height: 480,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSlate),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Toolbar Dark
          Container(
            color: const Color(0xFF1E293B),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'Rapor_Sem1_JohnDoe.pdf',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.chevron_left, color: Colors.white54, size: 18),
                    const Text('1/4', style: TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                    const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Text('100%', style: TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace')),
                    const SizedBox(width: 8),
                    const Icon(Icons.download, color: Color(0xFFA7F3D0), size: 16),
                  ],
                ),
              ],
            ),
          ),
          // Canvas Dokumen Kertas
          Expanded(
            child: Container(
              color: const Color(0xFF020617),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15)],
                  ),
                  child: Column(
                    children: [
                      // Kop Surat
                      const Text('KEMENTERIAN PENDIDIKAN DAN KEBUDAYAAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      const Text('SD NEGERI 1 JAKARTA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                      const Text('Jl. Pendidikan No. 10, Jakarta Selatan • NPSN: 20109281', style: TextStyle(fontSize: 8, color: textSlate)),
                      const Divider(color: darkSlate, thickness: 1.5, height: 16),
                      const Text('LAPORAN HASIL BELAJAR (RAPOR)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
                      const SizedBox(height: 12),
                      
                      // Biodata Grid
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: backgroundSlate, borderRadius: BorderRadius.circular(4)),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Nama : John Doe', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                              Text('NISN : 0039281726', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                            ]),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Kelas    : 1 SD - A', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                              Text('Semester : 1 (Ganjil)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tabel Nilai
                      Table(
                        border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 0.5),
                        columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(4), 2: FlexColumnWidth(1.5), 3: FlexColumnWidth(1.5)},
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFF1E293B)),
                            children: [
                              _buildTableCell('No', isHeader: true, align: TextAlign.center),
                              _buildTableCell('Mata Pelajaran', isHeader: true),
                              _buildTableCell('Nilai', isHeader: true, align: TextAlign.center),
                              _buildTableCell('Predikat', isHeader: true, align: TextAlign.center),
                            ],
                          ),
                          _buildTableRow('1', 'Pendidikan Agama', '88', 'A', isGreen: true),
                          _buildTableRow('2', 'Pendidikan Pancasila', '85', 'A', isGreen: true, isEven: true),
                          _buildTableRow('3', 'Bahasa Indonesia', '86', 'B+', isGreen: false),
                          _buildTableRow('4', 'Matematika Wajib', '82', 'B', isGreen: false, isEven: true),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Catatan Wali Kelas
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFFFFBEB), border: Border.all(color: const Color(0xFFFDE68A)), borderRadius: BorderRadius.circular(4)),
                        child: const Text(
                          'Catatan Wali Kelas:\nAnanda John menunjukkan perkembangan yang sangat baik pada semester ini, khususnya dalam kepemimpinan dan rasa ingin tahu.',
                          style: TextStyle(fontSize: 8, color: Color(0xFF92400E), height: 1.3),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tanda Tangan Digital
                      Align(
                        alignment: Alignment.centerRight,
                        child: Column(
                          children: [
                            const Text('Jakarta, 20 Desember 2025\nWali Kelas 1A,', textAlign: TextAlign.center, style: TextStyle(fontSize: 8)),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              width: 40, height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(border: Border.all(color: primaryTeal, style: BorderStyle.solid), borderRadius: BorderRadius.circular(4)),
                              child: const Text('✔ TTD', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: primaryTeal)),
                            ),
                            const Text('Ibu Siska, S.Pd', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                            const Text('NIP. 198801202015032001', style: TextStyle(fontSize: 7, color: textSlate)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 8,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? Colors.white : darkSlate,
        ),
      ),
    );
  }

  TableRow _buildTableRow(String no, String mapel, String nilai, String predikat, {required bool isGreen, bool isEven = false}) {
    return TableRow(
      decoration: BoxDecoration(color: isEven ? const Color(0xFFF8FAFC) : Colors.white),
      children: [
        _buildTableCell(no, align: TextAlign.center),
        _buildTableCell(mapel),
        _buildTableCell(nilai, align: TextAlign.center),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Text(
            predikat,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isGreen ? primaryTeal : const Color(0xFF2563EB)),
          ),
        ),
      ],
    );
  }
}