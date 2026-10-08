import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/elearning/models/elearning_model.dart';

void main() {
  group('CourseDetail parsing', () {
    test('accepts mixed numeric/string JSON values and null descriptions', () {
      final detail = CourseDetail.fromJson({
        'id': '42',
        'title': 'Dasar Pemrograman',
        'teacher_name': 'Budi Santoso',
        'description': null,
        'total_slides': '3',
        'slides': [
          {
            'id': '10',
            'title': 'Pengenalan',
            'material_type': 'video',
            'download_url': null,
            'sequence': '0',
          },
          {
            'id': 11,
            'title': 'Latihan',
            'material_type': 'document',
            'download_url': 'https://example.com/materi.pdf',
            'sequence': 1,
          },
        ],
      });

      expect(detail.id, 42);
      expect(detail.totalSlides, 3);
      expect(detail.description, isEmpty);
      expect(detail.slides.length, 2);
      expect(detail.slides[0].materialType, 'video');
      expect(detail.slides[1].downloadUrl, 'https://example.com/materi.pdf');
      expect(detail.slides[0].sequence, 0);
    });

    test('parses persisted course and slide completion progress', () {
      final detail = CourseDetail.fromJson({
        'id': 42,
        'title': 'Dasar Pemrograman',
        'teacher_name': 'Budi Santoso',
        'description': '',
        'total_slides': 2,
        'completed_slides': 1,
        'progress_percent': 50,
        'slides': [
          {
            'id': 10,
            'title': 'Pengenalan',
            'material_type': 'document',
            'sequence': 1,
            'is_completed': true,
          },
          {
            'id': 11,
            'title': 'Modul interaktif',
            'material_type': 'scorm',
            'sequence': 2,
            'is_completed': false,
          },
        ],
      });

      expect(detail.completedSlides, 1);
      expect(detail.progressPercent, 50);
      expect(detail.slides.map((slide) => slide.isCompleted), [true, false]);
    });
  });

  group('CourseMessage parsing', () {
    test('parses message metadata and ownership', () {
      final message = CourseMessage.fromJson({
        'id': '12',
        'author_name': 'Siswa',
        'body': 'Halo',
        'created_at': '2026-10-07 08:00:00',
        'is_own': true,
      });

      expect(message.id, 12);
      expect(message.authorName, 'Siswa');
      expect(message.body, 'Halo');
      expect(message.createdAt, DateTime(2026, 10, 7, 8));
      expect(message.isOwn, isTrue);
    });
  });
}
