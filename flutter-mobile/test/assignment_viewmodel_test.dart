import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/kurikulum/assignments/local/assignment_local_storage.dart';
import 'package:flutter_application_1/features/kurikulum/assignments/models/assignment_model.dart';
import 'package:flutter_application_1/features/kurikulum/assignments/repositories/assignment_repository.dart';
import 'package:flutter_application_1/features/kurikulum/assignments/services/assignment_service.dart';
import 'package:flutter_application_1/features/kurikulum/assignments/viewmodel/assignment_viewmodel.dart';
import 'package:flutter_application_1/services/tenant_api_config.dart';

class _FakeAssignmentRepository extends AssignmentRepository {
  _FakeAssignmentRepository()
    : super(
        apiService: AssignmentService(
          baseUrl: 'https://example.com/api/v1',
          tenantApiConfig: TenantApiConfig(),
        ),
        localStorage: AssignmentLocalStorage(),
      );

  List<AssignmentItem> assignments = [];
  List<Map<String, dynamic>>? cachedAssignments;
  final Map<String, Completer<List<AssignmentItem>>> pendingResponses = {};

  @override
  Future<List<AssignmentItem>> getAssignments(
    String token, {
    bool forceRefresh = false,
  }) async {
    final pendingResponse = pendingResponses[token];
    return pendingResponse == null ? assignments : pendingResponse.future;
  }

  @override
  Future<Map<String, dynamic>> submitAssignment({
    required String token,
    required int assignmentId,
    required Stream<List<int>> fileStream,
    required int fileSize,
    required String fileName,
  }) async => {
    'submission_id': 18,
    'attachment_id': 42,
    'file_name': fileName,
    'state': 'submitted',
    'submitted_at': '2026-10-05T06:00:00',
  };

  @override
  Future<void> saveCachedAssignments(
    List<Map<String, dynamic>> data, {
    required String token,
  }) async {
    cachedAssignments = data;
  }
}

void main() {
  test(
    'late response from previous user cannot replace current assignments',
    () async {
      final repository = _FakeAssignmentRepository();
      final viewModel = AssignmentViewModel(repository: repository);
      final firstUserResponse = Completer<List<AssignmentItem>>();
      final secondUserResponse = Completer<List<AssignmentItem>>();
      repository.pendingResponses['first-user'] = firstUserResponse;
      repository.pendingResponses['second-user'] = secondUserResponse;

      final firstUserFetch = viewModel.fetchAssignments(
        'first-user',
        forceRefresh: true,
      );
      final secondUserFetch = viewModel.fetchAssignments(
        'second-user',
        forceRefresh: true,
      );

      secondUserResponse.complete([_assignment(title: 'Tugas user kedua')]);
      await secondUserFetch;
      firstUserResponse.complete([_assignment(title: 'Tugas user pertama')]);
      await firstUserFetch;

      expect(viewModel.items.single.title, 'Tugas user kedua');
    },
  );

  test(
    'successful upload adds student attachment even when assignment list is empty',
    () async {
      final repository = _FakeAssignmentRepository();
      final viewModel = AssignmentViewModel(repository: repository);
      final assignment = AssignmentItem(
        id: 3,
        masterAssignmentId: 3,
        title: 'Tugas',
        subject: SubjectInfo(name: 'PAI'),
        facultyId: 1,
        batchId: 3,
        description: '',
        state: 'publish',
        maxMarks: 100,
      );

      final updatedAssignment = await viewModel.submitAssignment(
        token: 'token',
        assignment: assignment,
        fileStream: Stream<List<int>>.empty(),
        fileSize: 100 * 1024,
        fileName: 'jawaban.pdf',
      );

      final submission = updatedAssignment.studentSubmission!;
      expect(submission.id, 18);
      expect(submission.state, 'submitted');
      expect(submission.attachments.single.id, 42);
      expect(submission.attachments.single.fileName, 'jawaban.pdf');
      expect(viewModel.items.single.studentSubmission, same(submission));
      expect(
        repository.cachedAssignments!.single['student_submission'],
        isNotNull,
      );
    },
  );
}

AssignmentItem _assignment({required String title}) => AssignmentItem(
  id: title == 'Tugas user pertama' ? 1 : 2,
  masterAssignmentId: 1,
  title: title,
  subject: SubjectInfo(name: 'PAI'),
  facultyId: 1,
  batchId: 3,
  description: '',
  state: 'publish',
  maxMarks: 100,
);
