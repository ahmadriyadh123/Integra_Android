int _asInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String _normalizeMaterialType(dynamic value) {
  final type = _asString(value, fallback: 'document').toLowerCase();
  if (type == 'video') return 'video';
  if (type == 'scorm') return 'scorm';
  if (type == 'quiz' || type == 'question') return 'quiz';
  if (type == 'document' || type == 'pdf' || type == 'file') return 'document';
  return 'document';
}

String? _asOptionalString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

class SlideItem {
  final int id;
  final String title;
  final String materialType; // 'document', 'video', 'scorm', 'quiz'
  final String? downloadUrl;
  final int sequence;

  SlideItem({
    required this.id,
    required this.title,
    required this.materialType,
    this.downloadUrl,
    required this.sequence,
  });

  bool get isPdf => materialType == 'document';
  bool get isVideo => materialType == 'video';
  bool get isScorm => materialType == 'scorm';
  bool get isQuiz => materialType == 'quiz';

  factory SlideItem.fromJson(Map<String, dynamic> json) {
    return SlideItem(
      id: _asInt(json['id']),
      title: _asString(json['title'], fallback: '-'),
      materialType: _normalizeMaterialType(json['material_type']),
      downloadUrl: _asOptionalString(json['download_url']),
      sequence: _asInt(json['sequence']),
    );
  }
}

class CourseDetail {
  final int id;
  final String title;
  final String teacherName;
  final String description;
  final int totalSlides;
  final List<SlideItem> slides;

  CourseDetail({
    required this.id,
    required this.title,
    required this.teacherName,
    required this.description,
    required this.totalSlides,
    required this.slides,
  });

  factory CourseDetail.fromJson(Map<String, dynamic> json) {
    final rawSlides = json['slides'] as List<dynamic>? ?? [];
    return CourseDetail(
      id: _asInt(json['id']),
      title: _asString(json['title'], fallback: '-'),
      teacherName: _asString(json['teacher_name'], fallback: '-'),
      description: _asString(json['description']),
      totalSlides: _asInt(json['total_slides']),
      slides: rawSlides
          .map((e) => SlideItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class CourseItem {
  final int id;
  final String title;
  final String teacherName;
  final int totalSlides;
  final String description;

  CourseItem({
    required this.id,
    required this.title,
    required this.teacherName,
    required this.totalSlides,
    required this.description,
  });

  factory CourseItem.fromJson(Map<String, dynamic> json) {
    return CourseItem(
      id: _asInt(json['id']),
      title: _asString(json['title'], fallback: '-'),
      teacherName: _asString(json['teacher_name'], fallback: '-'),
      totalSlides: _asInt(json['total_slides']),
      description: _asString(json['description']),
    );
  }
}
