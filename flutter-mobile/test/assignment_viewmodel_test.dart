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
  List<AttachmentItem> submissionAttachments = [];
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
  Future<AssignmentSubmissionResult> submitAssignment({
    required String token,
    required int assignmentId,
    required List<AssignmentFileUpload> files,
  }) async => AssignmentSubmissionResult(
    submissionId: 18,
    attachmentId: 42,
    fileName: files.first.fileName,
    attachments: [
      for (var index = 0; index < files.length; index++)
        AttachmentItem(
          id: 42 + index,
          fileName: files[index].fileName,
          fileUrl: '',
          uploadedByRole: 'student',
        ),
    ],
    state: 'submitted',
    submittedAt: DateTime.parse('2026-10-05T06:00:00'),
  );

  @override
  Future<AssignmentSubmissionResult> updateSubmissionAttachments({
    required String token,
    required int assignmentId,
    required List<AssignmentFileUpload> files,
    required List<int> removeAttachmentIds,
  }) async {
    submissionAttachments = [
      ...submissionAttachments.where(
        (attachment) => !removeAttachmentIds.contains(attachment.id),
      ),
      for (var index = 0; index < files.length; index++)
        AttachmentItem(
          id: 90 + index,
          fileName: files[index].fileName,
          fileUrl: '',
          uploadedByRole: 'student',
        ),
    ];
    return AssignmentSubmissionResult(
      submissionId: 18,
      attachmentId: submissionAttachments.first.id,
      fileName: submissionAttachments.first.fileName,
      attachments: submissionAttachments,
      state: 'submitted',
      submittedAt: DateTime.parse('2026-10-05T06:00:00'),
    );
  }

  @override
  Future<void> saveCachedAssignments(
    List<AssignmentItem> data, {
    required String token,
  }) async {
    cachedAssignments = data.map((item) => item.toJson()).toList();
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
    'successful submission adds all selected attachments when list is empty',
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
        files: [
          AssignmentFileUpload(
            stream: Stream<List<int>>.empty(),
            size: 100 * 1024,
            fileName: 'jawaban.pdf',
          ),
          AssignmentFileUpload(
            stream: Stream<List<int>>.empty(),
            size: 200 * 1024,
            fileName: 'lampiran.docx',
          ),
        ],
      );

      final submission = updatedAssignment.studentSubmission!;
      expect(submission.id, 18);
      expect(submission.state, 'submitted');
      expect(submission.attachments, hasLength(2));
      expect(
        submission.attachments.map((attachment) => attachment.fileName),
        ['jawaban.pdf', 'lampiran.docx'],
      );
      expect(
        submission.attachments.map((attachment) => attachment.fileUrl),
        [
          '/assignments/3/attachments/42',
          '/assignments/3/attachments/43',
        ],
      );
      expect(viewModel.items.single.studentSubmission, same(submission));
      expect(
        repository.cachedAssignments!.single['student_submission'],
        isNotNull,
      );
    },
  );

  test('updating attachments replaces state and saves cache', () async {
    final repository = _FakeAssignmentRepository()
      ..submissionAttachments = [
        AttachmentItem(
          id: 42,
          fileName: 'old.pdf',
          fileUrl: '/assignments/3/attachments/42',
          uploadedByRole: 'student',
        ),
        AttachmentItem(
          id: 43,
          fileName: 'keep.docx',
          fileUrl: '/assignments/3/attachments/43',
          uploadedByRole: 'student',
        ),
      ];
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
      studentSubmission: StudentSubmission(
        id: 18,
        state: 'submitted',
        marks: 0,
        attachments: repository.submissionAttachments,
      ),
    );

    final updated = await viewModel.updateSubmissionAttachments(
      token: 'token',
      assignment: assignment,
      files: [
        AssignmentFileUpload(
          stream: Stream<List<int>>.empty(),
          size: 100,
          fileName: 'new.pdf',
        ),
      ],
      removeAttachmentIds: [42],
    );

    expect(
      updated.studentSubmission!.attachments.map((attachment) => attachment.id),
      [43, 90],
    );
    expect(
      updated.studentSubmission!.attachments.map(
        (attachment) => attachment.fileName,
      ),
      ['keep.docx', 'new.pdf'],
    );
    expect(
      repository.cachedAssignments!.single['student_submission']['attachments'],
      hasLength(2),
    );
  });
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
