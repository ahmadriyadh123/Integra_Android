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
      id: json['id'] as int,
      title: json['title'] as String? ?? '-',
      materialType: json['material_type'] as String? ?? 'document',
      downloadUrl: json['download_url'] as String?,
      sequence: json['sequence'] as int? ?? 0,
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
      id: json['id'] as int,
      title: json['title'] as String? ?? '-',
      teacherName: json['teacher_name'] as String? ?? '-',
      description: json['description'] as String? ?? '',
      totalSlides: json['total_slides'] as int? ?? 0,
      slides: rawSlides
          .map((e) => SlideItem.fromJson(e as Map<String, dynamic>))
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
      id: json['id'] as int,
      title: json['title'] as String? ?? '-',
      teacherName: json['teacher_name'] as String? ?? '-',
      totalSlides: json['total_slides'] as int? ?? 0,
      description: json['description'] as String? ?? '',
    );
  }
}
