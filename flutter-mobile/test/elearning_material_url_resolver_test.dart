import 'package:flutter_application_1/features/elearning/services/material_url_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const apiBaseUrl = 'https://kp-sekolah.asetkoptii.com/mobile-api/api/v1';

  test('retains the public API mount prefix for relative SCORM URLs', () {
    final uri = resolveElearningMaterialUri(
      '/api/v1/elearning/content/29/download',
      apiBaseUrl,
    );

    expect(
      uri.toString(),
      'https://kp-sekolah.asetkoptii.com/mobile-api/api/v1/elearning/content/29/download',
    );
  });

  test('keeps direct Odoo file paths rooted at the host', () {
    final uri = resolveElearningMaterialUri(
      '/web/content/2067?download=true',
      apiBaseUrl,
    );

    expect(
      uri.toString(),
      'https://kp-sekolah.asetkoptii.com/web/content/2067?download=true',
    );
  });

  test('leaves absolute material URLs unchanged', () {
    const url = 'https://cdn.example.test/course/lesson.zip';

    expect(resolveElearningMaterialUri(url, apiBaseUrl).toString(), url);
  });
}
