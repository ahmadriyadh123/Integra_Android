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
