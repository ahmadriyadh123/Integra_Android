import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../local/notification_local_storage.dart';
import '../services/notification_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationLocalStorage _storage;
  NotificationService? _service;

  NotificationViewModel({NotificationLocalStorage? storage, NotificationService? service})
      : _storage = storage ?? NotificationLocalStorage(),
        _service = service;

  /// Set service setelah construct (dipakai oleh provider untuk inject baseUrl/config).
  void configure(NotificationService service) {
    _service = service;
  }

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _lastCursor;
  String? _lastError;
  String? get lastError => _lastError;
  static const _cursorKey = 'app_notifications_cursor';

  // ── Local storage ────────────────────────────────────────────────────────────

  /// Load dari local storage saat aplikasi dibuka.
  Future<void> loadFromStorage() async {
    _isLoading = true;
    notifyListeners();
    _notifications = await _storage.loadNotifications();
    _unreadCount = await _storage.loadUnreadCount();
    _lastCursor = await _storage.loadCursor();
    _isLoading = false;
    notifyListeners();
  }

  // ── API fetch ─────────────────────────────────────────────────────────────────

  /// Fetch notifikasi baru dari backend, merge dengan yang sudah ada di local.
  /// Set [forceFullSync] true untuk abaikan cursor dan cek 30 hari terakhir.
  Future<void> fetchFromApi(String token, {bool forceFullSync = false}) async {
    if (_service == null) return;
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final cursor = forceFullSync ? null : _lastCursor;
      final result = await _service!.fetchNotifications(
        token,
        cursor: cursor,
      );

      // Merge: tambah hanya notifikasi yang ID-nya belum ada
      int newCount = 0;
      for (final notif in result.notifications) {
        if (!_notifications.any((n) => n.id == notif.id)) {
          _notifications.insert(0, notif);
          newCount++;
        }
      }
      if (newCount > 0) {
        _unreadCount += newCount;
      }

      // Simpan cursor untuk poll berikutnya
      if (result.nextCursor != null) {
        _lastCursor = result.nextCursor;
        await _storage.saveCursor(result.nextCursor!);
      }

      // Sort by createdAt DESC
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Simpan ke local storage
      await _storage.saveNotifications(_notifications);
    } catch (e) {
      _lastError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Aksi user ────────────────────────────────────────────────────────────────

  /// Tandai satu notifikasi sebagai sudah dibaca.
  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx < 0) return;
    final notif = _notifications[idx];
    if (notif.isRead) return;
    _notifications[idx] = notif.copyWith(isRead: true);
    _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
    await _storage.saveNotifications(_notifications);
    notifyListeners();
  }

  /// Tandai semua sebagai sudah dibaca.
  Future<void> markAllAsRead() async {
    if (_notifications.every((n) => n.isRead)) return;
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    await _storage.saveNotifications(_notifications);
    notifyListeners();
  }

  /// Hapus satu notifikasi.
  Future<void> deleteNotification(String id) async {
    final removed = _notifications.firstWhere(
      (n) => n.id == id,
      orElse: () => _notifications.first,
    );
    _notifications.removeWhere((n) => n.id == id);
    if (!removed.isRead) {
      _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
    }
    await _storage.saveNotifications(_notifications);
    notifyListeners();
  }

  /// Hapus semua notifikasi.
  Future<void> clearAll() async {
    _notifications = [];
    _unreadCount = 0;
    _lastCursor = null;
    await _storage.clearAll();
    notifyListeners();
  }
}
