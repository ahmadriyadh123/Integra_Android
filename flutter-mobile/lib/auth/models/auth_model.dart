class UserProfile {
  final int userId;
  final int? partnerId;
  final int? studentId;
  final String name;
  final String username;
  final String email;
  final String className;
  final String jenjang;
  final String nis;
  final String nisn;
  final String rombel;
  final String tempatTanggalLahir;
  final String usia;
  final bool isPortal;

  UserProfile({
    required this.userId,
    this.partnerId,
    this.studentId,
    required this.name,
    required this.username,
    required this.email,
    this.className = '',
    this.jenjang = 'sd',
    this.nis = '',
    this.nisn = '',
    this.rombel = '',
    this.tempatTanggalLahir = '',
    this.usia = '',
    this.isPortal = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final String parsedName = json['name'] as String? ??
        json['nama_lengkap'] as String? ??
        json['full_name'] as String? ??
        '';

    final String parsedNis = json['nis'] as String? ??
        json['gr_no'] as String? ??
        '';

    final String parsedNisn = json['nisn'] as String? ?? '';

    final String parsedClassName = json['class_name'] as String? ??
        json['kelas'] as String? ??
        json['kelas_name'] as String? ??
        '';

    final String parsedRombel = json['rombel'] as String? ??
        json['rombel_name'] as String? ??
        '';

    String parsedTtl = json['tempat_tanggal_lahir'] as String? ?? '';
    if (parsedTtl.isEmpty) {
      final String bp = json['birth_place'] as String? ?? '';
      final String bd = json['birth_date'] as String? ?? '';
      if (bp.isNotEmpty && bd.isNotEmpty) {
        parsedTtl = '$bp, $bd';
      } else if (bp.isNotEmpty) {
        parsedTtl = bp;
      } else if (bd.isNotEmpty) {
        parsedTtl = bd;
      }
    }

    final String parsedUsia = json['usia'] as String? ??
        (json['age'] != null ? json['age'].toString() : '');

    return UserProfile(
      userId: json['user_id'] as int? ?? json['id'] as int? ?? 0,
      partnerId: json['partner_id'] as int?,
      studentId: json['student_id'] as int?,
      name: parsedName,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      className: parsedClassName,
      jenjang: json['jenjang'] as String? ?? 'sd',
      nis: parsedNis,
      nisn: parsedNisn,
      rombel: parsedRombel,
      tempatTanggalLahir: parsedTtl,
      usia: parsedUsia,
      isPortal: json['is_portal'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'partner_id': partnerId,
      'student_id': studentId,
      'name': name,
      'username': username,
      'email': email,
      'class_name': className,
      'jenjang': jenjang,
      'nis': nis,
      'nisn': nisn,
      'rombel': rombel,
      'tempat_tanggal_lahir': tempatTanggalLahir,
      'usia': usia,
      'is_portal': isPortal,
    };
  }
}

class AuthResult {
  final String accessToken;
  final String tokenType;
  final UserProfile user;

  AuthResult({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
