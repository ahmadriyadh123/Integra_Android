import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_application_1/features/elearning/local/elearning_local_storage.dart';
import 'package:flutter_application_1/features/elearning/repositories/elearning_repository.dart';
import 'package:flutter_application_1/features/elearning/services/elearning_service.dart';
import 'package:flutter_application_1/features/elearning/viewmodel/elearning_viewmodel.dart';
import 'package:flutter_application_1/features/elearning/models/elearning_model.dart';
import 'package:flutter_application_1/services/tenant_api_config.dart';

String _token({required int schoolId, required int userId}) {
  final header = base64Url
      .encode(utf8.encode(jsonEncode({'alg': 'HS256'})))
      .replaceAll('=', '');
  final payload = base64Url
      .encode(utf8.encode(jsonEncode({'school_id': schoolId, 'uid': userId})))
      .replaceAll('=', '');
  final signature = base64Url
      .encode(utf8.encode('test-signature'))
      .replaceAll('=', '');
  return '$header.$payload.$signature';
}

Map<String, dynamic> _course(int id, String title) => {
  'id': id,
  'title': title,
  'teacher_name': 'Guru',
  'total_slides': 2,
  'completed_slides': 0,
  'progress_percent': 0,
  'description': '',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late MockClient httpClient;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('elearning-sync-');
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    httpClient.close();
    await hiveDirectory.delete(recursive: true);
  });

  test(
    'merges delta by course id and scopes cache by school and user',
    () async {
      final requests = <Uri>[];
      var requestCount = 0;
      httpClient = MockClient((request) async {
        requests.add(request.url);
        requestCount++;
        final response = requestCount == 1
            ? {
                'success': true,
                'data': {
                  'items': [_course(1, 'Matematika'), _course(2, 'Bahasa')],
                  'removed_ids': <int>[],
                  'next_cursor': '2026-10-01T00:00:00Z',
                  'full_sync': true,
                },
              }
            : {
                'success': true,
                'data': {
                  'items': [
                    _course(1, 'Matematika Lanjutan'),
                    _course(3, 'IPA'),
                  ],
                  'removed_ids': [2],
                  'next_cursor': '2026-10-01T00:05:00Z',
                  'full_sync': false,
                },
              };
        return http.Response(
          jsonEncode(response),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = ElearningRepository(
        apiService: ElearningService(
          baseUrl: 'https://example.com/api/v1',
          tenantApiConfig: TenantApiConfig(schoolId: '4'),
          httpClient: httpClient,
        ),
        localStorage: ElearningLocalStorage(),
      );
      final token = _token(schoolId: 4, userId: 10);

      expect((await repository.getCourses(token)).map((course) => course.id), [
        2,
        1,
      ]);
      final updated = await repository.getCourses(token, forceRefresh: true);

      expect(updated.map((course) => (course.id, course.title)), [
        (3, 'IPA'),
        (1, 'Matematika Lanjutan'),
      ]);
      expect(requests[0].queryParameters, isEmpty);
      expect(requests[1].queryParameters['cursor'], '2026-10-01T00:00:00Z');
      expect(
        await repository.loadCachedCourses(_token(schoolId: 4, userId: 11)),
        isNull,
      );
    },
  );

  test(
    'course detail revalidates stale cache, falls back offline, and stores no binary payload',
    () async {
      var requestCount = 0;
      httpClient = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 5,
                'title': 'Kursus Terbaru',
                'teacher_name': 'Guru',
                'description': '',
                'total_slides': 1,
                'slides': [
                  {
                    'id': 51,
                    'title': 'Materi',
                    'material_type': 'document',
                    'download_url': 'https://example.com/content/51',
                    'sequence': 1,
                    'binary_payload': 'must-not-be-cached',
                  },
                ],
                'binary_payload': 'must-not-be-cached',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'success': false, 'detail': 'offline'}),
          503,
          headers: {'content-type': 'application/json'},
        );
      });

      final localStorage = ElearningLocalStorage();
      final repository = ElearningRepository(
        apiService: ElearningService(
          baseUrl: 'https://example.com/api/v1',
          tenantApiConfig: TenantApiConfig(schoolId: '4'),
          httpClient: httpClient,
        ),
        localStorage: localStorage,
      );
      final token = _token(schoolId: 4, userId: 10);
      await repository.saveCachedCourseDetail(
        token,
        5,
        CourseDetail(
          id: 5,
          title: 'Kursus Cache',
          teacherName: 'Guru',
          description: '',
          totalSlides: 1,
          slides: const [],
        ),
      );

      final viewModel = ElearningViewModel(repository: repository);
      await viewModel.fetchCourseDetail(token, 5);
      expect(viewModel.courseDetail?.title, 'Kursus Terbaru');
      final stored = await repository.loadCachedCourseDetail(token, 5);
      expect(stored, isNot(contains('binary_payload')));
      expect(
        (stored?['slides'] as List).single,
        isNot(contains('binary_payload')),
      );

      final box = await Hive.openBox(ElearningLocalStorage.boxName);
      await box.put('elearning_school_4_user_10_course_detail_ts_5', 0);
      await viewModel.fetchCourseDetail(token, 5);
      expect(viewModel.courseDetail?.title, 'Kursus Terbaru');
      expect(viewModel.detailError, contains('menampilkan cache lokal'));
      expect(requestCount, 2);
    },
  );
}
