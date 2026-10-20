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
  Set<String> _dismissedIds = {};
  bool _syncInProgress = false;

  // ── Local storage ────────────────────────────────────────────────────────────

  /// Load dari local storage saat aplikasi dibuka.
  Future<void> loadFromStorage() async {
    _isLoading = true;
    notifyListeners();
    _notifications = await _storage.loadNotifications();
    _unreadCount = await _storage.loadUnreadCount();
    _lastCursor = await _storage.loadCursor();
    _dismissedIds = await _storage.loadDismissedIds();
    _notifications = _notifications
        .where((notification) => !_dismissedIds.contains(notification.id))
        .toList();
    _unreadCount = _notifications.where((notification) => !notification.isRead).length;
    _isLoading = false;
    notifyListeners();
  }

  // ── API fetch ─────────────────────────────────────────────────────────────────

  /// Fetch notifikasi baru dari backend, merge dengan yang sudah ada di local.
  /// Set [forceFullSync] true untuk abaikan cursor dan cek 30 hari terakhir.
  Future<void> fetchFromApi(String token, {bool forceFullSync = false}) async {
    if (_service == null || _syncInProgress) return;
    _syncInProgress = true;
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final cursor = forceFullSync ? null : _lastCursor;
      final result = await _service!.fetchNotifications(
        token,
        cursor: cursor,
      );

      if (result.fullSync) {
        final previousById = {for (final item in _notifications) item.id: item};
        final serverIds = result.notifications.map((item) => item.id).toSet();
        // Keep dismissals only while the source record still exists. If it is
        // deleted upstream, it disappears from the snapshot and its tombstone
        // can be dropped too.
        _dismissedIds = _dismissedIds.intersection(serverIds);
        _notifications = result.notifications
            .where((item) => !_dismissedIds.contains(item.id))
            .map((item) => item.copyWith(
                  isRead: previousById[item.id]?.isRead ?? false,
                ))
            .toList();
        await _storage.saveDismissedIds(_dismissedIds);
      } else {
        for (final notif in result.notifications) {
          if (!_dismissedIds.contains(notif.id) &&
              !_notifications.any((n) => n.id == notif.id)) {
            _notifications.add(notif);
          }
        }
      }
      _unreadCount = _notifications.where((notification) => !notification.isRead).length;

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
      _syncInProgress = false;
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
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index < 0) return;
    final removed = _notifications[index];
    _notifications.removeWhere((n) => n.id == id);
    if (!removed.isRead) _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
    _dismissedIds.add(id);
    await _storage.saveDismissedIds(_dismissedIds);
    await _storage.saveNotifications(_notifications);
    notifyListeners();
  }

  /// Hapus semua notifikasi.
  Future<void> clearAll() async {
    _dismissedIds.addAll(_notifications.map((notification) => notification.id));
    _notifications = [];
    _unreadCount = 0;
    await _storage.saveDismissedIds(_dismissedIds);
    await _storage.saveNotifications(_notifications);
    notifyListeners();
  }
}
