import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/e-rapor/models/rapor_model.dart';
import 'package:flutter_application_1/features/e-rapor/services/rapor_pdf_generator_service.dart';
import 'package:flutter_application_1/features/auth/models/auth_model.dart';

void main() {
  group('RaporPdfGeneratorService Tests', () {
    test('generateRaporPdf creates non-empty Uint8List PDF bytes', () async {
      final detail = ReportCardDetail(
        id: 1,
        studentId: 1,
        studentName: 'Budi Santoso',
        className: 'Kelas 1 SD',
        averageScore: 88.5,
        teacherNotes: 'Sangat tekun dan rajin.',
        subjects: [
          SubjectGrade(
            id: 1,
            subjectName: 'Matematika',
            nilaiPengetahuan: 90,
            nilaiKeterampilan: 85,
            predicate: 'Sangat Baik (A)',
          ),
        ],
        pdfUrl: '',
        fileName: 'Rapor_Budi.pdf',
      );

      final header = ReportCardHeader(
        id: 1,
        studentId: 1,
        studentName: 'Budi Santoso',
        academicYear: '2025/2026',
        semester: '1 (Gasal)',
        className: 'Kelas 1 SD',
        averageScore: 88.5,
        teacherNotes: 'Catatan wali kelas',
        decisionStatus: 'LULUS',
        pdfUrl: '',
        fileName: 'Rapor_Budi.pdf',
      );

      final user = UserProfile(
        userId: 1,
        name: 'Budi Santoso',
        username: 'budi',
        email: 'budi@example.com',
        nis: '12345',
        nisn: '67890',
        partnerId: 1,
      );

      final Uint8List pdfBytes =
          await RaporPdfGeneratorService.generateRaporPdf(detail, header, user);

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(0));
    });

    test(
      'missing report data does not add sample identities or grades',
      () async {
        final detail = ReportCardDetail(
          id: 1,
          studentId: 1,
          studentName: '-',
          className: '-',
          averageScore: 0,
          teacherNotes: '-',
          subjects: const [],
        );

        final pdfBytes = await RaporPdfGeneratorService.generateRaporPdf(
          detail,
          null,
          null,
        );
        final pdfContent = _extractPdfText(pdfBytes);

        expect(pdfBytes.length, greaterThan(0));
        expect(pdfContent, contains('Data nilai belum tersedia.'));
        expect(pdfContent, isNot(contains('Siswa 2')));
        expect(pdfContent, isNot(contains('123 / 123')));
        expect(pdfContent, isNot(contains('2025/2026')));
        expect(pdfContent, isNot(contains('Kelas 1 SD')));
        expect(pdfContent, isNot(contains('Pendidikan Pancasila')));
        expect(pdfContent, isNot(contains('17 Juni 2026')));
      },
    );
  });
}

String _extractPdfText(Uint8List pdfBytes) {
  final rawPdf = latin1.decode(pdfBytes);
  final streamMatch = RegExp(
    r'/Filter/FlateDecode/Length (\d+)>>stream\n',
  ).firstMatch(rawPdf);
  if (streamMatch == null) {
    throw StateError('PDF content stream was not found.');
  }

  final streamStart = streamMatch.end;
  final streamLength = int.parse(streamMatch.group(1)!);
  final contentBytes = ZLibDecoder().convert(
    pdfBytes.sublist(streamStart, streamStart + streamLength),
  );
  final content = latin1.decode(contentBytes);
  return RegExp(r'\[\((.*?)\)\]TJ')
      .allMatches(content)
      .map(
        (match) =>
            match.group(1)!.replaceAll(r'\(', '(').replaceAll(r'\)', ')'),
      )
      .join(' ');
}
