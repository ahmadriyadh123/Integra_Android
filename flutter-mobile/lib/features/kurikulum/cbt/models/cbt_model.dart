int? _parseId(dynamic value) {
  if (value is int && value >= 0) return value;
  if (value is num && value >= 0) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String _stringValue(dynamic value, {String fallback = ''}) =>
    value is String ? value : fallback;

Map<String, dynamic> _jsonObject(dynamic value, String message) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw FormatException(message);
  }
  return Map<String, dynamic>.from(value);
}

class CbtExamSchedule {
  final int id;
  final String title;
  final String examType;
  final String dateRange;
  final int durationMinutes;
  final int questionCount;
  final String status;
  final String rawStatus;

  const CbtExamSchedule({
    required this.id,
    required this.title,
    required this.examType,
    required this.dateRange,
    required this.durationMinutes,
    required this.questionCount,
    required this.status,
    required this.rawStatus,
  });

  factory CbtExamSchedule.fromJson(Map<String, dynamic> json) {
    final id = _parseId(json['id']);
    if (id == null || id <= 0) {
      throw const FormatException('ID jadwal CBT tidak valid.');
    }
    return CbtExamSchedule(
      id: id,
      title: _stringValue(
        json['judul_ujian'] ?? json['name'],
        fallback: 'Ujian',
      ),
      examType: _stringValue(json['jenis_ujian']),
      dateRange: _stringValue(json['rentang_waktu']),
      durationMinutes: _parseId(json['durasi_menit']) ?? 0,
      questionCount: _parseId(json['jumlah_soal']) ?? 0,
      status: _stringValue(json['status']),
      rawStatus: _stringValue(json['raw_status'], fallback: _stringValue(json['status'])),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'judul_ujian': title,
    'jenis_ujian': examType,
    'rentang_waktu': dateRange,
    'durasi_menit': durationMinutes,
    'jumlah_soal': questionCount,
    'status': status,
    'raw_status': rawStatus,
  };
}

class CbtScheduleSyncResult {
  final List<CbtExamSchedule> exams;
  final List<int> removedIds;
  final String cursor;
  final bool isFullSync;

  const CbtScheduleSyncResult({
    required this.exams,
    required this.removedIds,
    required this.cursor,
    required this.isFullSync,
  });

  factory CbtScheduleSyncResult.fromJson(Map<String, dynamic> json) {
    final records = json['exams'];
    final removed = json['removed_ids'];
    final cursor = json['cursor'];
    final fullSync = json['is_full_sync'];
    if (records is! List ||
        removed is! List ||
        cursor is! String ||
        cursor.isEmpty ||
        fullSync is! bool) {
      throw const FormatException('Respons sinkronisasi CBT tidak valid.');
    }
    return CbtScheduleSyncResult(
      exams: records
          .map(
            (record) => CbtExamSchedule.fromJson(
              _jsonObject(record, 'Record jadwal CBT tidak valid.'),
            ),
          )
          .toList(),
      removedIds: removed.map((id) {
        final parsed = _parseId(id);
        if (parsed == null || parsed <= 0) {
          throw const FormatException('ID jadwal CBT yang dihapus tidak valid.');
        }
        return parsed;
      }).toList(),
      cursor: cursor,
      isFullSync: fullSync,
    );
  }
}

class CbtAnswerOption {
  final int id;
  final String code;
  final String text;

  const CbtAnswerOption({
    required this.id,
    required this.code,
    required this.text,
  });

  factory CbtAnswerOption.fromJson(Map<String, dynamic> json) {
    final id = _parseId(json['id']);
    if (id == null || id <= 0) {
      throw const FormatException('ID pilihan jawaban CBT tidak valid.');
    }
    return CbtAnswerOption(
      id: id,
      code: _stringValue(json['kode']),
      text: _stringValue(json['teks_jawaban']),
    );
  }
}

class CbtQuestion {
  final int id;
  final String type;
  final String text;
  final num scoreWeight;
  final List<CbtAnswerOption> options;

  const CbtQuestion({
    required this.id,
    required this.type,
    required this.text,
    required this.scoreWeight,
    required this.options,
  });

  factory CbtQuestion.fromJson(Map<String, dynamic> json) {
    final id = _parseId(json['id']);
    final rawOptions = json['options'];
    if (id == null || id <= 0 || rawOptions is! List) {
      throw const FormatException('Data soal CBT tidak valid.');
    }
    return CbtQuestion(
      id: id,
      type: _stringValue(json['jenis_soal'], fallback: 'pilihan_ganda'),
      text: _stringValue(json['pertanyaan']),
      scoreWeight: json['bobot_nilai'] is num
          ? json['bobot_nilai'] as num
          : num.tryParse(json['bobot_nilai']?.toString() ?? '') ?? 1,
      options: rawOptions
          .map(
            (option) => CbtAnswerOption.fromJson(
              _jsonObject(option, 'Pilihan jawaban CBT tidak valid.'),
            ),
          )
          .toList(),
    );
  }
}

class CbtExamData {
  final String title;
  final List<CbtQuestion> questions;

  const CbtExamData({required this.title, required this.questions});

  factory CbtExamData.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    if (rawQuestions is! List) {
      throw const FormatException('Daftar soal CBT tidak valid.');
    }
    return CbtExamData(
      title: _stringValue(json['judul_ujian']),
      questions: rawQuestions
          .map(
            (question) => CbtQuestion.fromJson(
              _jsonObject(question, 'Data soal CBT tidak valid.'),
            ),
          )
          .toList(),
    );
  }
}

class CbtAnswer {
  final int questionId;
  final int? selectedOptionId;
  final String questionType;

  const CbtAnswer({
    required this.questionId,
    required this.selectedOptionId,
    required this.questionType,
  });

  Map<String, dynamic> toJson() => {
    'soal_id': questionId,
    'jawaban_pilihan_id': selectedOptionId,
    'jawaban_text': null,
    'jenis_soal': questionType,
  };
}

class CbtSubmitResult {
  final int totalQuestions;
  final int answeredQuestions;
  final int unansweredQuestions;

  const CbtSubmitResult({
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.unansweredQuestions,
  });

  factory CbtSubmitResult.fromJson(Map<String, dynamic> json) {
    final totalQuestions = _parseId(json['jumlah_soal']);
    final answeredQuestions = _parseId(json['jumlah_dijawab']);
    final unansweredQuestions = _parseId(json['jumlah_tidak_dijawab']);
    if (totalQuestions == null ||
        answeredQuestions == null ||
        unansweredQuestions == null) {
      throw const FormatException('Respons hasil CBT tidak valid.');
    }
    return CbtSubmitResult(
      totalQuestions: totalQuestions,
      answeredQuestions: answeredQuestions,
      unansweredQuestions: unansweredQuestions,
    );
  }
}
