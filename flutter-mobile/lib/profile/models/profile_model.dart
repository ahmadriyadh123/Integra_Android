class StudentProfile {
  final int id;
  final int userId;
  final String photoUrl;
  final String name;
  final String nis;
  final String nisn;
  final String className;
  final String rombel;
  final String tempatTanggalLahir;
  final String usia;
  final bool isActive;

  const StudentProfile({
    required this.id,
    required this.userId,
    required this.photoUrl,
    required this.name,
    required this.nis,
    required this.nisn,
    required this.className,
    required this.rombel,
    required this.tempatTanggalLahir,
    required this.usia,
    required this.isActive,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      photoUrl: _asString(json['foto_siswa']),
      name: _asString(json['nama_lengkap']),
      nis: _asString(json['nis']),
      nisn: _asString(json['nisn']),
      className: _asString(json['kelas']),
      rombel: _asString(json['rombel']),
      tempatTanggalLahir: _asString(json['tempat_tanggal_lahir']),
      usia: _asString(json['usia']),
      isActive: json['status_aktif'] as bool? ?? true,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _asString(dynamic value) => value?.toString() ?? '';
}
