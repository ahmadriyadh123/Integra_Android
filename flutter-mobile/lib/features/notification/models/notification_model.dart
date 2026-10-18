/// Tipe notifikasi — menentukan ikon dan warna aksen.
enum NotificationType {
  rapor,
  weeklyPlan,
  assignment,
  attendance,
  bukuKomunikasi,
  cbt,
  tagihan,
  general,
}

extension NotificationTypeExt on NotificationType {
  String get label => switch (this) {
        NotificationType.rapor          => 'E-Rapor',
        NotificationType.weeklyPlan    => 'Weekly Plan',
        NotificationType.assignment    => 'Tugas',
        NotificationType.attendance    => 'Kehadiran',
        NotificationType.bukuKomunikasi => 'Buku Komunikasi',
        NotificationType.cbt          => 'Ujian CBT',
        NotificationType.tagihan       => 'Tagihan',
        NotificationType.general       => 'Umum',
      };

  String get key => switch (this) {
        NotificationType.rapor          => 'rapor',
        NotificationType.weeklyPlan    => 'weekly_plan',
        NotificationType.assignment    => 'assignment',
        NotificationType.attendance    => 'attendance',
        NotificationType.bukuKomunikasi => 'buku_komunikasi',
        NotificationType.cbt           => 'cbt',
        NotificationType.tagihan       => 'tagihan',
        NotificationType.general       => 'general',
      };

  static NotificationType fromKey(String key) {
    return NotificationType.values.firstWhere(
      (e) => e.key == key,
      orElse: () => NotificationType.general,
    );
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.key,
        'title': title,
        'body': body,
        'created_at': createdAt.toIso8601String(),
        'is_read': isRead,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: NotificationTypeExt.fromKey(json['type'] as String? ?? 'general'),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  /// Factory untuk parse item dari response backend GET /notifications.
  ///
  /// Backend mengembalikan:
  /// {
  ///   "kategori": "rapor",
  ///   "ref_id": 8,
  ///   "judul": "STS",
  ///   "isi": "Rapor STS semester 1 telah tersedia",
  ///   "created_at": "2026-10-17T12:00:00"
  /// }
  factory AppNotification.fromApiItem(Map<String, dynamic> item, String kategori) {
    final refId = item['ref_id'];
    final refIdStr = refId?.toString() ?? '';
    return AppNotification(
      id: '${kategori}_$refIdStr',
      type: NotificationTypeExt.fromKey(kategori),
      title: item['judul'] as String? ?? '',
      body: item['isi'] as String? ?? '',
      createdAt: DateTime.tryParse(
              item['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
