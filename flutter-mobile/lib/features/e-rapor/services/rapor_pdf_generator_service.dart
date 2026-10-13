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

    final studentName = _firstAvailable([
      detail.studentName,
      user?.name,
    ]);
    final nis = _displayValue(user?.nis);
    final nisn = _displayValue(user?.nisn);
    final academicYear = _displayValue(header?.academicYear);
    final className = _firstAvailable([detail.className, header?.className]);
    final semester = _displayValue(header?.semester);
    final reportType = _displayValue(header?.reportType);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'LAPORAN HASIL BELAJAR PESERTA DIDIK',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (reportType != '-')
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Text(
                        reportType,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  pw.SizedBox(height: 8),
                  pw.Divider(thickness: 1, color: PdfColors.grey400),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Nama Peserta Didik: $studentName',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Kelas: $className',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'NIS: $nis',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'NISN: $nisn',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Tahun Ajaran: $academicYear',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Semester: $semester',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            pw.Text(
              'MUATAN PEMBELAJARAN',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),

            _buildSubjectsTable(detail.subjects),

            pw.SizedBox(height: 24),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Mengetahui,',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Orang Tua / Wali',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 40),
                    pw.Text(
                      '( .................................... )',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Tanggal Pengesahan: -',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Wali Kelas', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 40),
                    pw.Text(
                      '( Wali Kelas $className )',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
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

  static String _displayValue(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty || normalized == '-'
        ? '-'
        : normalized;
  }

  static String _firstAvailable(Iterable<String?> values) {
    for (final value in values) {
      final normalized = _displayValue(value);
      if (normalized != '-') return normalized;
    }
    return '-';
  }

  static pw.Widget _buildSubjectsTable(List<SubjectGrade> subjects) {
    if (subjects.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        ),
        child: pw.Text(
          'Data nilai belum tersedia.',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      );
    }

    final List<pw.TableRow> rows = [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _tableCell('No', bold: true, centered: true),
          _tableCell('Mata Pelajaran', bold: true),
          _tableCell('Nilai Pengetahuan', bold: true, centered: true),
          _tableCell('Nilai Keterampilan', bold: true, centered: true),
          _tableCell('Capaian Kompetensi', bold: true),
        ],
      ),
    ];

    for (int i = 0; i < subjects.length; i++) {
      final subject = subjects[i];
      rows.add(
        pw.TableRow(
          children: [
            _tableCell('${i + 1}', centered: true),
            _tableCell(_displayValue(subject.subjectName)),
            _tableCell(
              subject.nilaiPengetahuan.toString(),
              centered: true,
            ),
            _tableCell(
              subject.nilaiKeterampilan.toString(),
              centered: true,
            ),
            _tableCell(_displayValue(subject.predicate)),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FlexColumnWidth(2.4),
        2: const pw.FixedColumnWidth(58),
        3: const pw.FixedColumnWidth(58),
        4: const pw.FlexColumnWidth(2),
      },
      children: rows,
    );
  }

  static pw.Widget _tableCell(
    String value, {
    bool bold = false,
    bool centered = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        value,
        textAlign: centered ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
