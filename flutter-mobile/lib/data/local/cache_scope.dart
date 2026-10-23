import 'dart:convert';

String tokenCacheScope(
  String token, {
  bool includeCourse = false,
  bool includeStudent = false,
}) {
  final parts = token.split('.');
  if (parts.length != 3) {
    throw const FormatException('Token login tidak valid untuk cache.');
  }
  final payload = jsonDecode(
    utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
  );
  if (payload is! Map<String, dynamic>) {
    throw const FormatException('Klaim token tidak valid untuk cache.');
  }

  int? id(dynamic value) {
    if (value is int && value > 0) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  final school = id(payload['school_id']);
  final user = id(payload['uid']);
  final course = id(payload['course_id']);
  final student = id(payload['student_id']);
  if (school == null || user == null ||
      (includeCourse && course == null) ||
      (includeStudent && student == null)) {
    throw const FormatException('Identitas cache tidak lengkap pada token.');
  }
  return 'school_${school}_user_$user'
      '${course == null ? '' : '_course_$course'}'
      '${student == null ? '' : '_student_$student'}';
}
