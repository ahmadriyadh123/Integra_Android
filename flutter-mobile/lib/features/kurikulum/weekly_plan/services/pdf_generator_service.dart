import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/weekly_plan_detail_model.dart';

class PdfGeneratorService {
  // Helper memproses gambar Base64 dari backend
  static pw.MemoryImage? _base64ToPdfImage(String? base64String) {
    if (base64String == null || base64String.isEmpty || base64String == '-') return null;
    try {
      final cleanBase64 = base64String.contains(',') ? base64String.split(',').last : base64String;
      final bytes = base64Decode(cleanBase64);
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List> generateWeeklyPlanPdf(WeeklyPlanDetailModel data) async {
    final pdf = pw.Document();

    final logoImage = _base64ToPdfImage(data.logoBase64);
    final ttdKepsekImage = _base64ToPdfImage(data.ttdKepsekBase64);
    final ttdGuruImage = _base64ToPdfImage(data.ttdGuruBase64);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(25),
        build: (pw.Context context) {
          return [
            // ==================== HEADER SEKOLAH ====================
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        width: 40,
                        height: 40,
                        margin: const pw.EdgeInsets.only(right: 8),
                        child: pw.Image(logoImage),
                      ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(data.namaSekolah, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text(data.alamatSekolah, style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ],
                ),
                pw.Text('WEEKLY PLAN SD', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 1, color: PdfColors.teal),
            pw.SizedBox(height: 8),

            // ==================== INFO METADATA ====================
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Pekan: ${data.pekan}', style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Kelas: ${data.kelas}', style: const pw.TextStyle(fontSize: 9))),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Tahun Ajaran: ${data.tahunAjaran}', style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Semester: ${data.semester}', style: const pw.TextStyle(fontSize: 9))),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            // ==================== TEMA PEMBELAJARAN ====================
            pw.Container(
              color: PdfColors.teal,
              width: double.infinity,
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('TEMA PEMBELAJARAN', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.5)),
              child: pw.Text(data.tema, style: const pw.TextStyle(fontSize: 9)),
            ),
            pw.SizedBox(height: 10),

            // ==================== TUJUAN PEMBELAJARAN ====================
            pw.Container(
              color: PdfColors.teal,
              width: double.infinity,
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('TUJUAN PEMBELAJARAN', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center),
            ),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.teal50),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Mata Pelajaran', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Tujuan Pembelajaran', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...data.tujuanPembelajaran.map(
                  (tp) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(tp.subjectName, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(tp.tp, style: const pw.TextStyle(fontSize: 8))),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            // ==================== HARIAN (SENIN - JUMAT) ====================
            _buildDayTable('Senin', data.senin),
            _buildDayTable('Selasa', data.selasa),
            _buildDayTable('Rabu', data.rabu),
            _buildDayTable('Kamis', data.kamis),
            _buildDayTable('Jumat', data.jumat),

            pw.SizedBox(height: 15),

            // ==================== FOOTER TANDA TANGAN ====================
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Kiri: Mengetahui Kepsek
                pw.Column(
                  children: [
                    pw.Text('Mengetahui,', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Kepala Sekolah', style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      height: 35,
                      width: 80,
                      child: ttdKepsekImage != null ? pw.Image(ttdKepsekImage) : pw.SizedBox(),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(data.namaKepsek, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),

                // Kanan: Wali Kelas
                pw.Column(
                  children: [
                    pw.Text('Wali Kelas', style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 12),
                    pw.Container(
                      height: 35,
                      width: 80,
                      child: ttdGuruImage != null ? pw.Image(ttdGuruImage) : pw.SizedBox(),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(data.namaGuru, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
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

  static pw.Widget _buildDayTable(String dayName, List<DailyActivity> activities) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          color: PdfColors.teal,
          width: double.infinity,
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(dayName, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8)),
        ),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.teal50),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Waktu', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Aktivitas Pembelajaran', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Media', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Sumber Belajar', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Penilaian', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
              ],
            ),
            ...activities.map(
              (act) => pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(act.waktu, style: const pw.TextStyle(fontSize: 7))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(act.aktivitas, style: const pw.TextStyle(fontSize: 7))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(act.media, style: const pw.TextStyle(fontSize: 7))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(act.sumber, style: const pw.TextStyle(fontSize: 7))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(act.penilaian, style: const pw.TextStyle(fontSize: 7))),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
      ],
    );
  }
}