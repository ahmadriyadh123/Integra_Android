class SchoolOption {
  const SchoolOption({required this.id, required this.name});

  final String id;
  final String name;

  factory SchoolOption.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int ? rawId.toString() : rawId?.toString().trim();
    final name = json['nama_sekolah'];
    if (id == null ||
        int.tryParse(id) == null ||
        name is! String ||
        name.trim().isEmpty) {
      throw const FormatException('Data sekolah tidak valid');
    }

    return SchoolOption(id: id, name: name.trim());
  }

  Map<String, dynamic> toJson() => {'id': id, 'nama_sekolah': name};
}
