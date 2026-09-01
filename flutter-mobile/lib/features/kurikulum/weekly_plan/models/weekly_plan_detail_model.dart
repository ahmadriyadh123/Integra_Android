class DailyActivity {
  final int id;
  final String waktu;
  final String aktivitas;
  final String media;
  final String sumber;
  final String penilaian;

  DailyActivity({
    required this.id,
    required this.waktu,
    required this.aktivitas,
    required this.media,
    required this.sumber,
    required this.penilaian,
  });

  factory DailyActivity.fromJson(Map<String, dynamic> json) {
    return DailyActivity(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      waktu: json['waktu']?.toString() ?? '-',
      aktivitas: json['aktivitas']?.toString() ?? '-',
      media: json['media']?.toString() ?? '-',
      sumber: json['sumber']?.toString() ?? '-',
      penilaian: json['penilaian']?.toString() ?? '-',
    );
  }
}

class TargetPembelajaran {
  final int id;
  final String subjectName;
  final String tp;

  TargetPembelajaran({
    required this.id,
    required this.subjectName,
    required this.tp,
  });

  factory TargetPembelajaran.fromJson(Map<String, dynamic> json) {
    return TargetPembelajaran(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      subjectName: json['subject_name']?.toString() ?? 'Mata Pelajaran',
      tp: json['tp']?.toString() ?? '-',
    );
  }
}

class WeeklyPlanDetailModel {
  final int id;
  final String namaSekolah;
  final String alamatSekolah;
  final String kelas;
  final String semester;
  final String tahunAjaran;
  final String pekan;
  final String tema;
  final String namaGuru;
  final String namaKepsek;
  final String status;
  final List<TargetPembelajaran> tujuanPembelajaran;
  final List<DailyActivity> senin;
  final List<DailyActivity> selasa;
  final List<DailyActivity> rabu;
  final List<DailyActivity> kamis;
  final List<DailyActivity> jumat;
  final String? logoBase64;
  final String? ttdKepsekBase64;
  final String? ttdGuruBase64;

  WeeklyPlanDetailModel({
    required this.id,
    required this.namaSekolah,
    required this.alamatSekolah,
    required this.kelas,
    required this.semester,
    required this.tahunAjaran,
    required this.pekan,
    required this.tema,
    required this.namaGuru,
    required this.namaKepsek,
    required this.status,
    required this.tujuanPembelajaran,
    required this.senin,
    required this.selasa,
    required this.rabu,
    required this.kamis,
    required this.jumat,
    this.logoBase64,
    this.ttdKepsekBase64,
    this.ttdGuruBase64,
  });

  factory WeeklyPlanDetailModel.fromJson(Map<String, dynamic> json) {
    List<DailyActivity> parseList(dynamic rawList) {
      if (rawList is List) {
        return rawList.map((e) => DailyActivity.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      return [];
    }

    List<TargetPembelajaran> parseTp(dynamic rawList) {
      if (rawList is List) {
        return rawList.map((e) => TargetPembelajaran.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      return [];
    }

    return WeeklyPlanDetailModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      namaSekolah: json['nama_sekolah']?.toString() ?? 'ERP Integra Edusolusi',
      alamatSekolah: json['alamat_sekolah']?.toString() ?? '-',
      kelas: json['kelas']?.toString() ?? '-',
      semester: json['semester']?.toString() ?? '-',
      tahunAjaran: json['tahun_ajaran']?.toString() ?? '-',
      pekan: json['pekan']?.toString() ?? '-',
      tema: json['tema']?.toString() ?? '-',
      namaGuru: json['nama_guru']?.toString() ?? '-',
      namaKepsek: json['nama_kepsek']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'draft',
      tujuanPembelajaran: parseTp(json['tujuan_pembelajaran']),
      senin: parseList(json['senin']),
      selasa: parseList(json['selasa']),
      rabu: parseList(json['rabu']),
      kamis: parseList(json['kamis']),
      jumat: parseList(json['jumat']),
      logoBase64: json['logo_base64']?.toString(),
      ttdKepsekBase64: json['ttd_kepsek_base64']?.toString(),
      ttdGuruBase64: json['ttd_guru_base64']?.toString(),
    );
  }
}