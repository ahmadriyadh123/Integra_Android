import '../local/cbt_local_storage.dart';
import '../services/cbt_service.dart';
import 'package:flutter_application_1/services/cache_scope.dart';

class CbtRepository {
  final CbtService apiService;
  final CbtLocalStorage localStorage;
  String? lastSyncError;

  CbtRepository({required this.apiService, required this.localStorage});

  /// Mengambil daftar ujian CBT dengan cache-first strategy.
  /// Mengembalikan list exam mentah.
  Future<List<Map<String, dynamic>>> getCbtSchedules(
    String token, {
    bool forceRefresh = false,
  }) async {
    final scope = tokenCacheScope(token, includeStudent: true);
    final snapshot = await localStorage.loadCbtSnapshot(scope: scope);
    final cached = snapshot?['items'] as List<dynamic>?;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final cursor = snapshot?['cursor'] as String?;
      final fullSyncAt = snapshot?['full_sync_at'] as int?;
      final shouldFullSync =
          forceRefresh ||
          cursor == null ||
          fullSyncAt == null ||
          now - fullSyncAt >= const Duration(hours: 24).inMilliseconds;
      final data = await apiService.syncCbtSchedules(
        token,
        cursor: shouldFullSync ? null : cursor,
      );
      final records = data['exams'];
      final removedIds = data['removed_ids'];
      final nextCursor = data['cursor'];
      final isFullSync = data['is_full_sync'];
      if (records is! List ||
          removedIds is! List ||
          nextCursor is! String ||
          isFullSync is! bool ||
          isFullSync != shouldFullSync) {
        throw const FormatException('Respons sinkronisasi CBT tidak valid.');
      }
      final changed = records
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final schedules = <int, Map<String, dynamic>>{};
      if (!isFullSync && cached != null) {
        for (final record in cached) {
          if (record is Map && record['id'] is int) {
            schedules[record['id'] as int] = Map<String, dynamic>.from(record);
          }
        }
      }
      for (final removedId in removedIds) {
        if (removedId is int) schedules.remove(removedId);
      }
      for (final record in changed) {
        final id = record['id'];
        if (id is int) schedules[id] = record;
      }
      final result = schedules.values.toList();
      await localStorage.saveCbtSchedules(
        result,
        scope: scope,
        cursor: nextCursor,
        fullSyncAt: isFullSync ? now : fullSyncAt,
      );
      lastSyncError = null;
      return result;
    } catch (error) {
      lastSyncError = error.toString();
      if (cached != null) {
        return cached.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      rethrow;
    }
  }

  /// Verifikasi token ke API
  Future<bool> verifyToken(
    String token,
    int jadwalId,
    String tokenInput,
  ) async {
    return await apiService.verifyExamToken(token, jadwalId, tokenInput);
  }

  /// Ambil soal ujian dari API
  Future<Map<String, dynamic>> getExamQuestions(
    String token,
    int jadwalId,
  ) async {
    return await apiService.fetchExamQuestions(token, jadwalId);
  }

  /// Submit jawaban ujian ke API
  Future<Map<String, dynamic>> submitExam(
    String token,
    int jadwalId,
    List<Map<String, dynamic>> answers,
    String? waktuMulai,
  ) async {
    return await apiService.submitExam(token, jadwalId, answers, waktuMulai);
  }
}
