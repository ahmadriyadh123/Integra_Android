import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_model.dart';

/// Penyimpanan lokal untuk notifikasi menggunakan SharedPreferences.
///
/// Menyimpan daftar notifikasi dan sekumpulan ID yang sudah dibaca,
/// sehingga status "sudah dibaca" bertelah saat aplikasi ditutup.
class NotificationLocalStorage {
  static const _keyNotifications = 'app_notifications';
  static const _keyUnreadCount = 'app_notifications_unread_count';
  static const _keyCursor = 'app_notifications_cursor';

  Future<List<AppNotification>> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyNotifications);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) =>
              AppNotification.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNotifications(List<AppNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_keyNotifications, encoded);
    final unread = notifications.where((n) => !n.isRead).length;
    await prefs.setInt(_keyUnreadCount, unread);
  }

  Future<int> loadUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUnreadCount) ?? 0;
  }

  Future<void> saveUnreadCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUnreadCount, count);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyNotifications);
    await prefs.remove(_keyUnreadCount);
    await prefs.remove(_keyCursor);
  }

  Future<String?> loadCursor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCursor);
  }

  Future<void> saveCursor(String cursor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCursor, cursor);
  }
}
