import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_application_1/features/calendar/local/calendar_local_storage.dart';
import 'package:flutter_application_1/features/calendar/repositories/calendar_repository.dart';
import 'package:flutter_application_1/features/calendar/services/calendar_service.dart';
import 'package:flutter_application_1/services/tenant_api_config.dart';

String _token({
  required int schoolId,
  required int userId,
  required int courseId,
}) {
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'school_id': schoolId,
            'uid': userId,
            'course_id': courseId,
          }),
        ),
      )
      .replaceAll('=', '');
  return 'header.$payload.signature';
}

class _CalendarService extends CalendarService {
  _CalendarService() : super(baseUrl: '', tenantApiConfig: TenantApiConfig());

  int requests = 0;

  @override
  Future<Map<String, dynamic>> fetchCalendars(String token) async {
    requests++;
    final courseId = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(token.split('.')[1]))),
    )['course_id'];
    return {
      'calendars': [
        {
          'id': courseId,
          'kelas': 'Kelas $courseId',
          'semester': 'Semester 1',
          'tahun_ajaran': '2026/2027',
          'link_dokumen': '',
          'status': '',
        },
      ],
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late _CalendarService apiService;
  late CalendarRepository repository;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('calendar-cache-');
    Hive.init(hiveDirectory.path);
    apiService = _CalendarService();
    repository = CalendarRepository(
      apiService: apiService,
      localStorage: CalendarLocalStorage(),
    );
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('calendar cache is isolated by school, user, and class', () async {
    final classThree = _token(schoolId: 4, userId: 17, courseId: 3);
    final classFour = _token(schoolId: 4, userId: 17, courseId: 4);

    expect((await repository.getCalendars(classThree)).single.kelas, 'Kelas 3');
    expect((await repository.getCalendars(classFour)).single.kelas, 'Kelas 4');
    expect((await repository.getCalendars(classThree)).single.kelas, 'Kelas 3');
    expect(apiService.requests, 2);
  });

  test('calendar cache scope requires tenant, user, and class claims', () {
    expect(
      () => repository.cacheScopeForToken('invalid-token'),
      throwsFormatException,
    );
    expect(
      () => repository.cacheScopeForToken(
        'header.${base64Url.encode(utf8.encode('{"school_id":4,"uid":17}'))}.signature',
      ),
      throwsFormatException,
    );
  });
}
