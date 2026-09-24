
class SubjectGrade {
  final int id;
  final int? subjectId;
  final String subjectName;
  final double nilaiPengetahuan;
  final double nilaiKeterampilan;
  final String predicate;

  SubjectGrade({
    required this.id,
    this.subjectId,
    required this.subjectName,
    required this.nilaiPengetahuan,
    required this.nilaiKeterampilan,
    required this.predicate,
  });

  factory SubjectGrade.fromJson(Map<String, dynamic> json) {
    return SubjectGrade(
      id: json['id'] as int,
      subjectId: json['subject_id'] as int?,
      subjectName: json['subject_name'] as String? ?? '-',
      nilaiPengetahuan: (json['nilai_pengetahuan'] as num?)?.toDouble() ?? 0.0,
      nilaiKeterampilan: (json['nilai_keterampilan'] as num?)?.toDouble() ?? 0.0,
      predicate: json['predikat'] as String? ?? '-',
    );
  }
}

class ReportCardHeader {
  final int id;
  final int studentId;
  final String studentName;
  final String className;
  final String semester;
  final String academicYear;
  final double averageScore;
  final String teacherNotes;
  final String decisionStatus;
  final String? pdfUrl;
  final String? fileName;

  ReportCardHeader({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.semester,
    required this.academicYear,
    required this.averageScore,
    required this.teacherNotes,
    required this.decisionStatus,
    this.pdfUrl,
    this.fileName,
  });

  factory ReportCardHeader.fromJson(Map<String, dynamic> json) {
    return ReportCardHeader(
      id: json['id'] as int,
      studentId: (json['student_id'] as num?)?.toInt() ?? 0,      
      studentName: json['student_name'] as String? ?? '-',
      className: json['kelas'] as String? ?? '-',
      semester: json['semester'] as String? ?? '-',
      academicYear: json['tahun_ajaran'] as String? ?? '-',
      averageScore: (json['rata_rata_nilai'] as num?)?.toDouble() ?? 0.0,
      teacherNotes: json['catatan_wali_kelas'] as String? ?? '-',
      decisionStatus: json['status_keputusan'] as String? ?? '-',
      pdfUrl: json['file_rapor_pdf'] as String?,
      fileName: json['file_name'] as String?,
    );
  }
}

class ReportCardDetail {
  final int id;
  final int studentId;
  final String studentName;
  final String className;
  final double averageScore;
  final String teacherNotes;
  final String? pdfUrl;
  final String? fileName;
  final List<SubjectGrade> subjects;

  ReportCardDetail({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.averageScore,
    required this.teacherNotes,
    this.pdfUrl,
    this.fileName,
    required this.subjects,
  });

  factory ReportCardDetail.fromJson(Map<String, dynamic> json) {
    return ReportCardDetail(
      id: json['id'] as int,
      studentId: (json['student_id'] as num?)?.toInt() ?? 0,
      studentName: json['student_name'] as String? ?? '-',
      className: json['kelas'] as String? ?? '-',
      averageScore: (json['rata_rata_nilai'] as num?)?.toDouble() ?? 0.0,
      teacherNotes: json['catatan_wali_kelas'] as String? ?? '-',
      pdfUrl: json['file_rapor_pdf'] as String?,
      fileName: json['file_name'] as String?,
      subjects: (json['subjects'] as List<dynamic>?)
          ?.map((e) => SubjectGrade.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList() ??
          [],
    );
  }
}