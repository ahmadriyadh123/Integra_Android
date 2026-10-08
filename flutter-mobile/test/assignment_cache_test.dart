import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter_application_1/features/kurikulum/assignments/local/assignment_local_storage.dart';
import 'package:flutter_application_1/features/kurikulum/assignments/repositories/assignment_repository.dart';
import 'package:flutter_application_1/features/kurikulum/assignments/services/assignment_service.dart';
import 'package:flutter_application_1/services/tenant_api_config.dart';

String _token({required int schoolId, required int userId}) {
  final payload = base64Url
      .encode(utf8.encode(jsonEncode({'school_id': schoolId, 'uid': userId})))
      .replaceAll('=', '');
  return 'header.$payload.signature';
}

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

  test('assignment caches are kept separate for different users and schools',
      () async {
    final userOne = _token(schoolId: 4, userId: 10);
    final userTwo = _token(schoolId: 4, userId: 11);
    final anotherSchool = _token(schoolId: 5, userId: 10);

    await repository.saveCachedAssignments([
      {'id': 1, 'title': 'Tugas user satu'},
    ], token: userOne);
    await repository.saveCachedAssignments([
      {'id': 2, 'title': 'Tugas user dua'},
    ], token: userTwo);
    await repository.saveCachedAssignments([
      {'id': 3, 'title': 'Tugas sekolah lain'},
    ], token: anotherSchool);

    expect(
      (await repository.loadCachedAssignments(userOne))!.single['id'],
      1,
    );
    expect(
      (await repository.loadCachedAssignments(userTwo))!.single['id'],
      2,
    );
    expect(
      (await repository.loadCachedAssignments(anotherSchool))!.single['id'],
      3,
    );
      });

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
