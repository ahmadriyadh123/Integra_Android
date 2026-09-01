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
  });
}
