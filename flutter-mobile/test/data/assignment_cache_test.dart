import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter_application_1/data/local/kurikulum/assignments/assignment_local_storage.dart';
import 'package:flutter_application_1/data/model/kurikulum/assignments/assignment_model.dart';
import 'package:flutter_application_1/data/repositories/kurikulum/assignments/assignment_repository.dart';
import 'package:flutter_application_1/data/services/kurikulum/assignments/assignment_service.dart';
import 'package:flutter_application_1/config/api/tenant_api_config.dart';

String _token({required int schoolId, required int userId, int studentId = 1}) {
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'school_id': schoolId,
            'uid': userId,
            'student_id': studentId,
          }),
        ),
      )
      .replaceAll('=', '');
  return 'header.$payload.signature';
}

AssignmentItem _assignment(int id, String title) => AssignmentItem(
  id: id,
  masterAssignmentId: id,
  title: title,
  subject: SubjectInfo(),
  facultyId: 0,
  batchId: 0,
  description: '',
  state: 'published',
  maxMarks: 100,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late AssignmentRepository repository;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('assignment-cache-');
    Hive.init(hiveDirectory.path);
    repository = AssignmentRepository(
      apiService: AssignmentService(
        baseUrl: 'https://example.com/api/v1',
        tenantApiConfig: TenantApiConfig(),
      ),
      localStorage: AssignmentLocalStorage(),
    );
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test(
    'assignment caches are kept separate for different users and schools',
    () async {
      final userOne = _token(schoolId: 4, userId: 10);
      final userTwo = _token(schoolId: 4, userId: 11);
      final anotherSchool = _token(schoolId: 5, userId: 10);

      await repository.saveCachedAssignments([
        _assignment(1, 'Tugas user satu'),
      ], token: userOne);
      await repository.saveCachedAssignments([
        _assignment(2, 'Tugas user dua'),
      ], token: userTwo);
      await repository.saveCachedAssignments([
        _assignment(3, 'Tugas sekolah lain'),
      ], token: anotherSchool);

      expect((await repository.loadCachedAssignments(userOne))!.single.id, 1);
      expect((await repository.loadCachedAssignments(userTwo))!.single.id, 2);
      expect(
        (await repository.loadCachedAssignments(anotherSchool))!.single.id,
        3,
      );
    },
  );

  test('cache scope requires tenant and user identity in the token', () {
    expect(
      () => repository.cacheScopeForToken('invalid-token'),
      throwsFormatException,
    );
    expect(
      () => repository.cacheScopeForToken(
        'header.${base64Url.encode(utf8.encode('{"uid":10}'))}.signature',
      ),
      throwsFormatException,
    );
  });
}
