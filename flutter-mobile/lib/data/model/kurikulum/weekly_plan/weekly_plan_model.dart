String _cleanHtml(String? text, {String fallback = '-'}) {
  if (text == null || text.isEmpty) return fallback;
  final cleaned = text.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();
  return cleaned.isEmpty ? fallback : cleaned;
}

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
      kelas: _cleanHtml(map['kelas']?.toString()),
      semester: _cleanHtml(map['semester']?.toString()),
      tahunAjaran: _cleanHtml(map['tahun_ajaran']?.toString()),
      pekan: _cleanHtml(map['pekan']?.toString()),
      tema: _cleanHtml(map['tema']?.toString()),
      namaGuru: _cleanHtml(map['nama_guru']?.toString()),
      status: map['status']?.toString() ?? 'draft',
    );
  }

  bool get isSubmitted => status == 'submitted' || status == 'approved';
}

