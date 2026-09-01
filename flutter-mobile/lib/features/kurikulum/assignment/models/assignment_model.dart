class SubjectInfo {
  final int? id;
  final String name;

  SubjectInfo({
    this.id,
    this.name = 'Umum',
  });

  factory SubjectInfo.fromJson(Map<String, dynamic> json) {
    return SubjectInfo(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name'] as String? ?? 'Umum',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

class AttachmentItem {
  final int id;
  final String fileName;
  final String fileUrl;
  final String uploadedByRole; // 'teacher' atau 'student'

  AttachmentItem({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.uploadedByRole,
  });

  factory AttachmentItem.fromJson(Map<String, dynamic> json) {
    return AttachmentItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      fileName: json['file_name'] as String? ?? 'File',
      fileUrl: json['file_url'] as String? ?? '',
      uploadedByRole: json['uploaded_by_role'] as String? ?? 'teacher',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'file_name': fileName,
        'file_url': fileUrl,
        'uploaded_by_role': uploadedByRole,
      };
}

class StudentSubmission {
  final int id;
  final String state; // 'draft', 'submitted', 'graded'
  final double marks;
  final DateTime? submittedAt;
  final List<AttachmentItem> attachments;

  StudentSubmission({
    required this.id,
    required this.state,
    required this.marks,
    this.submittedAt,
    this.attachments = const [],
  });

  factory StudentSubmission.fromJson(Map<String, dynamic> json) {
    return StudentSubmission(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      state: json['state'] as String? ?? 'draft',
      marks: (json['marks'] is num) ? (json['marks'] as num).toDouble() : 0.0,
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString())
          : null,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => AttachmentItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'state': state,
        'marks': marks,
        'submitted_at': submittedAt?.toIso8601String(),
        'attachments': attachments.map((e) => e.toJson()).toList(),
      };
}

class AssignmentItem {
  final int id;
  final int masterAssignmentId;
  final String title;
  final String assignmentType;
  final SubjectInfo subject;
  final int facultyId;
  final int batchId;
  final String description;
  final String state; // 'draft', 'published', 'cancel'
  final double maxMarks;
  final DateTime? issuedDate;
  final DateTime? submissionDeadline;
  final List<AttachmentItem> teacherAttachments;
  final StudentSubmission? studentSubmission;

  AssignmentItem({
    required this.id,
    required this.masterAssignmentId,
    required this.title,
    required this.assignmentType,
    required this.subject,
    required this.facultyId,
    required this.batchId,
    required this.description,
    required this.state,
    required this.maxMarks,
    this.issuedDate,
    this.submissionDeadline,
    this.teacherAttachments = const [],
    this.studentSubmission,
  });

  bool get isSubmitted => studentSubmission != null && (studentSubmission!.state == 'submitted' || studentSubmission!.state == 'graded');
  bool get isGraded => studentSubmission != null && studentSubmission!.state == 'graded';

  bool get isOverdue {
    if (submissionDeadline == null) return false;
    return DateTime.now().isAfter(submissionDeadline!) && !isSubmitted;
  }

  factory AssignmentItem.fromJson(Map<String, dynamic> json) {
    return AssignmentItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      masterAssignmentId: json['master_assignment_id'] is int
          ? json['master_assignment_id']
          : int.tryParse(json['master_assignment_id']?.toString() ?? '0') ?? 0,
      title: json['title'] as String? ?? 'Penugasan',
      assignmentType: json['assignment_type'] as String? ?? 'Tugas',
      subject: json['subject'] != null && json['subject'] is Map<String, dynamic>
          ? SubjectInfo.fromJson(json['subject'] as Map<String, dynamic>)
          : SubjectInfo(name: 'Umum'),
      facultyId: json['faculty_id'] is int ? json['faculty_id'] : int.tryParse(json['faculty_id']?.toString() ?? '0') ?? 0,
      batchId: json['batch_id'] is int ? json['batch_id'] : int.tryParse(json['batch_id']?.toString() ?? '0') ?? 0,
      description: json['description'] as String? ?? '',
      state: json['state'] as String? ?? 'draft',
      maxMarks: (json['max_marks'] is num) ? (json['max_marks'] as num).toDouble() : 100.0,
      issuedDate: json['issued_date'] != null ? DateTime.tryParse(json['issued_date'].toString()) : null,
      submissionDeadline: json['submission_deadline'] != null
          ? DateTime.tryParse(json['submission_deadline'].toString())
          : null,
      teacherAttachments: (json['teacher_attachments'] as List<dynamic>?)
              ?.map((e) => AttachmentItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      studentSubmission: json['student_submission'] != null && json['student_submission'] is Map<String, dynamic>
          ? StudentSubmission.fromJson(json['student_submission'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'master_assignment_id': masterAssignmentId,
        'title': title,
        'assignment_type': assignmentType,
        'subject': subject.toJson(),
        'faculty_id': facultyId,
        'batch_id': batchId,
        'description': description,
        'state': state,
        'max_marks': maxMarks,
        'issued_date': issuedDate?.toIso8601String(),
        'submission_deadline': submissionDeadline?.toIso8601String(),
        'teacher_attachments': teacherAttachments.map((e) => e.toJson()).toList(),
        'student_submission': studentSubmission?.toJson(),
      };
}
