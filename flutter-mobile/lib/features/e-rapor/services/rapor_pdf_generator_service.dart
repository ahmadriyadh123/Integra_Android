import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/rapor_model.dart';
import '../../auth/models/auth_model.dart';

class RaporPdfGeneratorService {
  static Future<Uint8List> generateRaporPdf(
    ReportCardDetail detail,
    ReportCardHeader? header,
    UserProfile? user,
  ) async {
    final pdf = pw.Document();

    final String studentName = detail.studentName.isNotEmpty && detail.studentName != '-'
        ? detail.studentName
        : (user?.name.isNotEmpty == true ? user!.name : 'Siswa 2');

    final String nisNisn = (user?.nis.isNotEmpty == true || user?.nisn.isNotEmpty == true)
        ? '${user?.nis ?? '123'} / ${user?.nisn ?? '123'}'
        : '123 / 123';

    final String academicYear = header?.academicYear.isNotEmpty == true && header?.academicYear != '-'
        ? header!.academicYear
        : '2025/2026';

    final String className = detail.className.isNotEmpty && detail.className != '-'
        ? detail.className
        : 'Kelas 1 SD';

    final String semester = header?.semester.isNotEmpty == true && header?.semester != '-'
        ? header!.semester
        : '1 (Gasal)';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            // Header / Kop
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'ERP Integra Edusolusi',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Jl. Pena Kencana Bumi Serpong Damai',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(thickness: 1, color: PdfColors.grey400),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Judul Dokumen
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'LAPORAN HASIL BELAJAR PESERTA DIDIK',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'TENGAH SEMESTER',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Tabel Informasi Peserta Didik
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Nama Peserta Didik : $studentName', style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Kelas : $className', style: const pw.TextStyle(fontSize: 9)),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('NIS/NISN : $nisNisn', style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Fase : A', style: const pw.TextStyle(fontSize: 9)),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Tahun Ajaran : $academicYear', style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Semester : $semester', style: const pw.TextStyle(fontSize: 9)),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Section 1: MUATAN PEMBELAJARAN
            pw.Text(
              'MUATAN PEMBELAJARAN',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),

            _buildSubjectsTable(detail.subjects),

            pw.SizedBox(height: 16),

            // Section 2: MUATAN LOKAL
            pw.Text(
              'MUATAN LOKAL',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),

            _buildMuatanLokalTable(),

            pw.SizedBox(height: 24),

            // Pengesahan Rapor / Footer Signature
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Mengetahui,', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Orang Tua / Wali', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 40),
                    pw.Text('( .................................... )', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Pengesahan Rapor : 17 Juni 2026', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Wali Kelas', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 40),
                    pw.Text('( Wali Kelas $className )', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSubjectsTable(List<SubjectGrade> subjects) {
    final List<pw.TableRow> rows = [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('No', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Mata Pelajaran', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Nilai Akhir', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Capaian Kompetensi', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Catatan Kompetensi', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
        ],
      ),
    ];

    if (subjects.isEmpty) {
      // Default sample subjects jika data dari server belum terisi
      final defaultList = [
        {'name': 'Pendidikan Agama dan Budi Pekerti', 'score': '88', 'pred': 'Sangat Baik (A)', 'notes': 'Menunjukkan penguasaan yang sangat baik dalam memahami nilai-nilai keagamaan.'},
        {'name': 'Pendidikan Pancasila', 'score': '85', 'pred': 'Baik (B)', 'notes': 'Menunjukkan pemahaman yang baik dalam menerapkan aturan dan norma sekolah.'},
        {'name': 'Bahasa Indonesia', 'score': '90', 'pred': 'Sangat Baik (A)', 'notes': 'Mampu membaca dan menulis kalimat sederhana dengan sangat baik.'},
        {'name': 'Matematika', 'score': '86', 'pred': 'Baik (B)', 'notes': 'Mampu melakukan penjumlahan dan pengurangan bilangan cacah.'},
      ];

      for (int i = 0; i < defaultList.length; i++) {
        final item = defaultList[i];
        rows.add(
          pw.TableRow(
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${i + 1}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item['name']!, style: const pw.TextStyle(fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item['score']!, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item['pred']!, style: const pw.TextStyle(fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item['notes']!, style: const pw.TextStyle(fontSize: 8))),
            ],
          ),
        );
      }
    } else {
      for (int i = 0; i < subjects.length; i++) {
        final s = subjects[i];
        final double finalScore = (s.nilaiPengetahuan + s.nilaiKeterampilan) > 0
            ? ((s.nilaiPengetahuan + s.nilaiKeterampilan) / 2)
            : s.nilaiPengetahuan;

        rows.add(
          pw.TableRow(
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${i + 1}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(s.subjectName, style: const pw.TextStyle(fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(finalScore.toStringAsFixed(0), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(s.predicate, style: const pw.TextStyle(fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Menunjukkan penguasaan materi yang ${s.predicate.toLowerCase()}', style: const pw.TextStyle(fontSize: 8))),
            ],
          ),
        );
      }
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FixedColumnWidth(45),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(3),
      },
      children: rows,
    );
  }

  static pw.Widget _buildMuatanLokalTable() {
    final defaultLokal = [
      {'name': 'Bahasa Sunda / Daerah', 'score': '88', 'notes': 'Sangat baik dalam memahami kosa kata sehari-hari.', 'capaian': 'Sangat Baik (A)'},
      {'name': 'Pendidikan Lingkungan Hidup', 'score': '90', 'notes': 'Aktif dan mandiri menjaga kebersihan lingkungan.', 'capaian': 'Sangat Baik (A)'},
    ];

    final List<pw.TableRow> rows = [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('No', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Mata Pelajaran', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Nilai Akhir', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Catatan Kompetensi', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Capaian Kompetensi', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
        ],
      ),
    ];

    for (int i = 0; i < defaultLokal.length; i++) {
      final item = defaultLokal[i];
      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${i + 1}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item['name']!, style: const pw.TextStyle(fontSize: 8))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item['score']!, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item['notes']!, style: const pw.TextStyle(fontSize: 8))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item['capaian']!, style: const pw.TextStyle(fontSize: 8))),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FixedColumnWidth(45),
        3: const pw.FlexColumnWidth(3),
        4: const pw.FlexColumnWidth(2),
      },
      children: rows,
    );
  }
}
