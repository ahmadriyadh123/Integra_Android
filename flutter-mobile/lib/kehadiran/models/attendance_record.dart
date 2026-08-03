class AttendanceRecord {
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
}