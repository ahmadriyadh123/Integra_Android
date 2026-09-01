class AttendanceRecord {
  final int id;
  final String studentName;
  final String kelas;
  final String rombel;
  final int hadir;
  final int sakit;
  final int izin;
  final int alpha;
  final String status;
  final String remark;
  final DateTime date;

  const AttendanceRecord({
    this.id = 0,
    required this.studentName,
    required this.kelas,
    required this.rombel,
    required this.hadir,
    required this.sakit,
    required this.izin,
    required this.alpha,
    required this.status,
    required this.remark,
    required this.date,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    bool present = json['present'] ?? false;
    bool sick = json['sick'] ?? false;
    bool excused = json['excused'] ?? false;
    bool absent = json['absent'] ?? false;

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['attendance_date'] ?? '');
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return AttendanceRecord(
      id: json['id'] ?? 0,
      studentName: json['student_name'] ?? 'Siswa',
      kelas: json['course_name'] ?? '-',
      rombel: json['batch_name'] ?? '-',
      hadir: present ? 1 : 0,
      sakit: sick ? 1 : 0,
      izin: excused ? 1 : 0,
      alpha: absent ? 1 : 0,
      status: json['status'] ?? '',
      remark: json['remark'] ?? '-',
      date: parsedDate,
    );
  }
}