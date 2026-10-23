class CalendarItem {
  final int id;
  final String kelas;
  final String semester;
  final String tahunAjaran;
  final String linkDokumen;
  final String status;

  CalendarItem({
    required this.id,
    required this.kelas,
    required this.semester,
    required this.tahunAjaran,
    required this.linkDokumen,
    required this.status,
  });

  factory CalendarItem.fromJson(Map<String, dynamic> json) {
    return CalendarItem(
      id: json['id'] as int,
      kelas: json['kelas'] as String? ?? '-',
      semester: json['semester'] as String? ?? '-',
      tahunAjaran: json['tahun_ajaran'] as String? ?? '-',
      linkDokumen: json['link_dokumen'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}
