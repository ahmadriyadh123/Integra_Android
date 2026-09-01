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

      final Uint8List pdfBytes = await RaporPdfGeneratorService.generateRaporPdf(
        detail,
        header,
        user,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(0));
    });
  });
}
