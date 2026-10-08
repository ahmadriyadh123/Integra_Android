import 'dart:convert';

class TenantApiConfig {
  TenantApiConfig({String schoolId = ''}) : schoolId = schoolId.trim();

  String schoolId;

  int? schoolIdFromToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3 ||
        parts.any((part) => part.isEmpty || !_isBase64Url(part))) {
      return null;
    }

    try {
      final header = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))),
      );
      if (header is! Map ||
          header['alg'] is! String ||
          (header['alg'] as String).isEmpty ||
          (header['alg'] as String).toLowerCase() == 'none') {
        return null;
      }
      if (base64Url.decode(base64Url.normalize(parts[2])).isEmpty) {
        return null;
      }

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map) return null;
      final rawSchoolId = payload['school_id'];
      if (rawSchoolId is int && rawSchoolId > 0) return rawSchoolId;
    } on FormatException {
      return null;
    }
    return null;
  }

  bool _isBase64Url(String segment) =>
      RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(segment);

  bool tokenMatchesSelectedSchool(String token) {
    final selectedSchoolId = int.tryParse(schoolId);
    return selectedSchoolId != null &&
        selectedSchoolId > 0 &&
        schoolIdFromToken(token) == selectedSchoolId;
  }

  Map<String, String> headers({String? token, bool includeContentType = true}) {
    if (token != null &&
        token.isNotEmpty &&
        !tokenMatchesSelectedSchool(token)) {
      throw const TenantTokenMismatchException();
    }

    return {
      if (includeContentType) 'Content-Type': 'application/json',
      if (schoolId.isNotEmpty) 'X-School-ID': schoolId,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
}

class TenantTokenMismatchException extends FormatException {
  const TenantTokenMismatchException()
    : super(
        'Token dari server tidak valid atau tidak sesuai dengan sekolah yang dipilih. '
        'Silakan periksa konfigurasi tenant atau login kembali.',
      );
}
