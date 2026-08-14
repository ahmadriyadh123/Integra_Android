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

  factory WeeklyPlanItem.fromJson(Map<String, dynamic> json) {
    return WeeklyPlanItem(
      id: json['id'] as int,
      kelas: json['kelas'] as String? ?? '-',
      semester: json['semester'] as String? ?? '-',
      tahunAjaran: json['tahun_ajaran'] as String? ?? '-',
      pekan: json['pekan'] as String? ?? '-',
      tema: json['tema'] as String? ?? '-',
      namaGuru: json['nama_guru'] as String? ?? '-',
      status: json['status'] as String? ?? 'draft',
    );
  }

  bool get isSubmitted => status == 'submitted' || status == 'approved';
}
