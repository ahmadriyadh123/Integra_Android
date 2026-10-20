import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/kurikulum/assignments/models/assignment_model.dart';

AssignmentItem _assignment({
  DateTime? deadline,
  String state = 'publish',
  StudentSubmission? submission,
}) => AssignmentItem(
  id: 3,
  masterAssignmentId: 3,
  title: 'Tugas',
  subject: SubjectInfo(name: 'PAI'),
  facultyId: 1,
  batchId: 3,
  description: '',
  state: state,
  maxMarks: 100,
  submissionDeadline: deadline,
  studentSubmission: submission,
);

void main() {
  test('submission response parses multiple uploaded attachments', () {
    final result = AssignmentSubmissionResult.fromJson({
      'submission_id': 18,
      'state': 'submitted',
      'attachments': [
        {'attachment_id': 42, 'file_name': 'jawaban.pdf'},
        {'attachment_id': 43, 'file_name': 'lampiran.docx'},
      ],
    });

    expect(result.attachments, hasLength(2));
    expect(result.attachments.map((item) => item.id), [42, 43]);
    expect(result.attachments.map((item) => item.fileName), [
      'jawaban.pdf',
      'lampiran.docx',
    ]);
  });

  test('allows upload for published assignment before deadline', () {
    final assignment = _assignment(
      deadline: DateTime.now().add(const Duration(days: 1)),
    );

    expect(assignment.canSubmit, isTrue);
  });

  test('does not allow upload after deadline', () {
    final assignment = _assignment(
      deadline: DateTime.now().subtract(const Duration(seconds: 1)),
    );

    expect(assignment.canSubmit, isFalse);
  });

  test('does not allow upload after submission', () {
    final assignment = _assignment(
      deadline: DateTime.now().add(const Duration(days: 1)),
      submission: StudentSubmission(
        id: 8,
        state: 'submitted',
        marks: 0,
        attachments: [
          AttachmentItem(
            id: 42,
            fileName: 'jawaban.pdf',
            fileUrl: '/assignments/3/attachments/42',
            uploadedByRole: 'student',
          ),
        ],
      ),
    );

    expect(assignment.canSubmit, isFalse);
  });

  test('recognizes stored attachment as a submitted assignment even in draft state', () {
    final assignment = _assignment(
      deadline: DateTime.now().add(const Duration(days: 1)),
      submission: StudentSubmission(
        id: 8,
        state: 'draft',
        marks: 0,
        attachments: [
          AttachmentItem(
            id: 42,
            fileName: 'jawaban.pdf',
            fileUrl: '/assignments/3/attachments/42',
            uploadedByRole: 'student',
          ),
        ],
      ),
    );

    expect(assignment.isSubmitted, isTrue);
    expect(assignment.needsSubmissionFile, isFalse);
    expect(assignment.canSubmit, isFalse);
  });

  test('allows editing submitted attachments before the deadline', () {
    final assignment = _assignment(
      deadline: DateTime.now().add(const Duration(days: 1)),
      submission: StudentSubmission(
        id: 8,
        state: 'submitted',
        marks: 0,
        attachments: [
          AttachmentItem(
            id: 42,
            fileName: 'jawaban.pdf',
            fileUrl: '/assignments/3/attachments/42',
            uploadedByRole: 'student',
          ),
        ],
      ),
    );

    expect(assignment.canSubmit, isFalse);
    expect(assignment.canEditSubmission, isTrue);
    expect(assignment.canManageSubmission, isTrue);
  });

  test('does not allow editing graded or overdue submissions', () {
    final graded = _assignment(
      deadline: DateTime.now().add(const Duration(days: 1)),
      submission: StudentSubmission(
        id: 8,
        state: 'graded',
        marks: 90,
      ),
    );
    final overdue = _assignment(
      deadline: DateTime.now().subtract(const Duration(seconds: 1)),
      submission: StudentSubmission(
        id: 9,
        state: 'submitted',
        marks: 0,
      ),
    );

    expect(graded.canEditSubmission, isFalse);
    expect(overdue.canEditSubmission, isFalse);
  });

  test('allows completing submitted state without a file before deadline', () {
    final assignment = _assignment(
      deadline: DateTime.now().add(const Duration(days: 1)),
      submission: StudentSubmission(id: 8, state: 'submit', marks: 0),
    );

    expect(assignment.needsSubmissionFile, isTrue);
    expect(assignment.canSubmit, isTrue);
  });

  test('does not allow completing fileless submission after deadline', () {
    final assignment = _assignment(
      deadline: DateTime.now().subtract(const Duration(seconds: 1)),
      submission: StudentSubmission(id: 8, state: 'submit', marks: 0),
    );

    expect(assignment.needsSubmissionFile, isTrue);
    expect(assignment.isOverdue, isTrue);
    expect(assignment.canSubmit, isFalse);
  });

  test('treats Odoo submit state without a file as incomplete', () {
    final assignment = _assignment(
      deadline: DateTime.now().add(const Duration(days: 1)),
      submission: StudentSubmission(id: 8, state: 'submit', marks: 0),
    );

    expect(assignment.isSubmitted, isTrue);
    expect(assignment.needsSubmissionFile, isTrue);
    expect(assignment.canSubmit, isTrue);
  });

  test('does not allow upload for unpublished assignment', () {
    expect(_assignment(state: 'draft').canSubmit, isFalse);
  });
}
