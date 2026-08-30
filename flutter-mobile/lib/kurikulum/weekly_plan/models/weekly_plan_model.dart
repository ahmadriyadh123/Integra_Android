class WeeklyPlanItem {
  final int id;
  final String kelas;
  final String semester;
  final String tahunAjaran;
  final String pekan;
  final String tema;
  final String namaGuru;
  final String status;

  WeeklyPlanItem({
    required this.id,
    required this.kelas,
    required this.semester,
    required this.tahunAjaran,
    required this.pekan,
    required this.tema,
    required this.namaGuru,
    required this.status,
  });

  factory WeeklyPlanItem.fromJson(Map<dynamic, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    return WeeklyPlanItem(
      id: (map['id'] is num)
          ? (map['id'] as num).toInt()
          : int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      kelas: map['kelas']?.toString() ?? '-',
      semester: map['semester']?.toString() ?? '-',
      tahunAjaran: map['tahun_ajaran']?.toString() ?? '-',
      pekan: map['pekan']?.toString() ?? '-',
      tema: map['tema']?.toString() ?? '-',
      namaGuru: map['nama_guru']?.toString() ?? '-',
      status: map['status']?.toString() ?? 'draft',
    );
  }

  bool get isSubmitted => status == 'submitted' || status == 'approved';
}

