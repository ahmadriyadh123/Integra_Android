import 'package:flutter_application_1/services/cache_scope.dart';

import '../local/cbt_local_storage.dart';
import '../models/cbt_model.dart';
import '../services/cbt_service.dart';

class CbtRepository {
  final CbtService apiService;
  final CbtLocalStorage localStorage;
  String? lastSyncError;

  CbtRepository({required this.apiService, required this.localStorage});

  Future<List<CbtExamSchedule>> getCbtSchedules(
    String token, {
    bool forceRefresh = false,
  }) async {
    final scope = tokenCacheScope(token, includeStudent: true);
    final snapshot = await localStorage.loadCbtSnapshot(scope: scope);
    final rawCached = snapshot?['items'];
    final cached = rawCached is List
        ? rawCached
              .map(
                (item) => CbtExamSchedule.fromJson(
                  _asObject(item, 'Data cache jadwal CBT tidak valid.'),
                ),
              )
              .toList()
        : null;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final cursor = snapshot?['cursor'] is String
          ? snapshot!['cursor'] as String
          : null;
      final fullSyncAt = snapshot?['full_sync_at'] is int
          ? snapshot!['full_sync_at'] as int
          : null;
      final shouldFullSync =
          forceRefresh ||
          cursor == null ||
          fullSyncAt == null ||
          now - fullSyncAt >= const Duration(hours: 24).inMilliseconds;
      final data = await apiService.syncCbtSchedules(
        token,
        cursor: shouldFullSync ? null : cursor,
      );
      if (data.isFullSync != shouldFullSync) {
        throw const FormatException('Respons sinkronisasi CBT tidak valid.');
      }

      final schedules = <int, CbtExamSchedule>{};
      if (!data.isFullSync && cached != null) {
        for (final schedule in cached) {
          schedules[schedule.id] = schedule;
        }
      }
      for (final removedId in data.removedIds) {
        schedules.remove(removedId);
      }
      for (final schedule in data.exams) {
        schedules[schedule.id] = schedule;
      }
      final result = schedules.values.toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      await localStorage.saveCbtSchedules(
        result.map((schedule) => schedule.toJson()).toList(),
        scope: scope,
        cursor: data.cursor,
        fullSyncAt: data.isFullSync ? now : fullSyncAt,
      );
      lastSyncError = null;
      return result;
    } catch (error) {
      lastSyncError = error.toString();
      if (cached != null) return cached;
      rethrow;
    }
  }

  Map<String, dynamic> _asObject(dynamic value, String message) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw FormatException(message);
    }
    return Map<String, dynamic>.from(value);
  }

  Future<bool> verifyToken(
    String token,
    int jadwalId,
    String tokenInput,
  ) {
    return apiService.verifyExamToken(token, jadwalId, tokenInput);
  }

  Future<CbtExamData> getExamQuestions(String token, int jadwalId) {
    return apiService.fetchExamQuestions(token, jadwalId);
  }

  Future<CbtSubmitResult> submitExam(
    String token,
    int jadwalId,
    List<CbtAnswer> answers,
    String? waktuMulai,
  ) {
    return apiService.submitExam(token, jadwalId, answers, waktuMulai);
  }
}
