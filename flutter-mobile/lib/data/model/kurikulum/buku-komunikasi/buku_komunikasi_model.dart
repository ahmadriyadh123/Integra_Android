enum BukuKomunikasiSubmitStatus { submitted, queued, failed }

class DailyNoteLine {
  final int id;
  final int pekanKe;
  final String bulan;
  final String senin;
  final String feedbackSenin;
  final String selasa;
  final String feedbackSelasa;
  final String rabu;
  final String feedbackRabu;
  final String kamis;
  final String feedbackKamis;
  final String jumat;
  final String feedbackJumat;
  final String? writeDate;

  DailyNoteLine({
    required this.id,
    required this.pekanKe,
    required this.bulan,
    required this.senin,
    required this.feedbackSenin,
    required this.selasa,
    required this.feedbackSelasa,
    required this.rabu,
    required this.feedbackRabu,
    required this.kamis,
    required this.feedbackKamis,
    required this.jumat,
    required this.feedbackJumat,
    this.writeDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'pekan_ke': pekanKe,
        'bulan': bulan,
        'senin': senin,
        'feedback_senin': feedbackSenin,
        'selasa': selasa,
        'feedback_selasa': feedbackSelasa,
        'rabu': rabu,
        'feedback_rabu': feedbackRabu,
        'kamis': kamis,
        'feedback_kamis': feedbackKamis,
        'jumat': jumat,
        'feedback_jumat': feedbackJumat,
        'write_date': writeDate,
      };

  factory DailyNoteLine.fromJson(Map<String, dynamic> json) {
    return DailyNoteLine(
      id: json['id'] as int? ?? 0,
      pekanKe: json['pekan_ke'] as int? ?? 1,
      bulan: json['bulan'] as String? ?? '-',
      senin: json['senin'] as String? ?? '-',
      feedbackSenin: json['feedback_senin'] as String? ?? '-',
      selasa: json['selasa'] as String? ?? '-',
      feedbackSelasa: json['feedback_selasa'] as String? ?? '-',
      rabu: json['rabu'] as String? ?? '-',
      feedbackRabu: json['feedback_rabu'] as String? ?? '-',
      kamis: json['kamis'] as String? ?? '-',
      feedbackKamis: json['feedback_kamis'] as String? ?? '-',
      jumat: json['jumat'] as String? ?? '-',
      feedbackJumat: json['feedback_jumat'] as String? ?? '-',
      writeDate: json['write_date'] as String?,
    );
  }
}

class BukuKomunikasiDetail {
  final int id;
  final String studentName;
  final String className;
  final String academicYear;
  final String status;
  final List<DailyNoteLine> lines;

  BukuKomunikasiDetail({
    required this.id,
    required this.studentName,
    required this.className,
    required this.academicYear,
    required this.status,
    required this.lines,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_name': studentName,
        'kelas': className,
        'tahun_ajaran': academicYear,
        'status': status,
        'lines': lines.map((l) => l.toJson()).toList(),
      };

  factory BukuKomunikasiDetail.fromJson(Map<String, dynamic> json) {
    return BukuKomunikasiDetail(
      id: json['id'] as int? ?? 0,
      studentName: json['student_name'] as String? ?? '-',
      className: json['kelas'] as String? ?? '-',
      academicYear: json['tahun_ajaran'] as String? ?? '-',
      status: json['status'] as String? ?? '-',
      lines: (json['lines'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => DailyNoteLine.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }
}