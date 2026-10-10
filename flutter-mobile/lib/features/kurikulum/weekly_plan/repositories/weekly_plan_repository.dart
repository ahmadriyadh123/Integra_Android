import 'dart:typed_data';
import '../local/weekly_plan_local_storage.dart';
import '../models/weekly_plan_model.dart';
import '../models/weekly_plan_detail_model.dart';
import '../services/weekly_plan_service.dart';
import 'package:flutter_application_1/services/cache_scope.dart';

class WeeklyPlanRepository {
  final WeeklyPlanService apiService;
  final WeeklyPlanLocalStorage localStorage;
  String? lastSyncError;

  WeeklyPlanRepository({
    required this.apiService,
    required this.localStorage,
  });

  Future<List<WeeklyPlanItem>> getWeeklyPlanList(String token, {bool forceRefresh = false}) async {
    final scope = tokenCacheScope(token, includeCourse: true);
    final snapshot = await localStorage.loadWeeklyPlanSnapshot(scope: scope);
    final rawCached = snapshot?['items'];
    final cached = rawCached is List
        ? rawCached.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : null;
    final fullSyncAt = snapshot?['full_sync_at'];
    final fullSync = cached == null ||
        fullSyncAt is! int ||
        DateTime.now().difference(
              DateTime.fromMillisecondsSinceEpoch(fullSyncAt),
            ) >=
            const Duration(hours: 24);
    try {
      final result = await apiService.syncWeeklyPlanList(
        token,
        cursor: fullSync ? null : snapshot?['cursor'] as String?,
      );
      final rawItems = result['items'];
      final removedIds = result['removed_ids'];
      final cursor = result['next_cursor'];
      final serverFullSync = result['full_sync'];
      if (rawItems is! List ||
          removedIds is! List ||
          cursor is! String ||
          cursor.isEmpty ||
          serverFullSync is! bool ||
          (fullSync && !serverFullSync)) {
        throw const FormatException(
          'Respons sinkronisasi Weekly Plan tidak lengkap.',
        );
      }
      final merged = <int, Map<String, dynamic>>{};
      if (!serverFullSync && cached != null) {
        for (final item in cached) {
          final id = _parseId(item['id']);
          if (id == null) {
            throw const FormatException('ID cache Weekly Plan tidak valid.');
          }
          merged[id] = item;
        }
      }
      for (final value in removedIds) {
        final id = _parseId(value);
        if (id == null) {
          throw const FormatException('ID Weekly Plan yang dihapus tidak valid.');
        }
        merged.remove(id);
      }
      for (final value in rawItems) {
        if (value is! Map) {
          throw const FormatException('Record Weekly Plan tidak valid.');
        }
        final item = Map<String, dynamic>.from(value);
        final id = _parseId(item['id']);
        if (id == null) {
          throw const FormatException('ID Weekly Plan tidak valid.');
        }
        merged[id] = item;
      }
      final data = merged.values.toList();
      final nextFullSyncAt = serverFullSync
          ? DateTime.now().millisecondsSinceEpoch
          : (fullSyncAt is int
                ? fullSyncAt
                : DateTime.now().millisecondsSinceEpoch);
      await localStorage.saveWeeklyPlanList(
        data,
        scope: scope,
        cursor: cursor,
        fullSyncAt: nextFullSyncAt,
      );
      lastSyncError = null;
      return data.whereType<Map>().map((e) => WeeklyPlanItem.fromJson(e)).toList();
    } catch (error) {
      lastSyncError = error.toString();
      if (cached != null) {
        return cached.whereType<Map>().map((e) => WeeklyPlanItem.fromJson(e)).toList();
      }
      rethrow;
    }
  }

  int? _parseId(dynamic value) {
    if (value is int && value > 0) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  /// Ambil detail dokumen dan mapping ke model
  Future<WeeklyPlanDetailModel> getWeeklyPlanDetail(int planId, String token) async {
    final data = await apiService.fetchWeeklyPlanDetail(planId, token);
    return WeeklyPlanDetailModel.fromJson(data);
  }

  /// Mengambil binary bytes PDF via Service
  Future<Uint8List> getWeeklyPlanPdfFile(int planId, String token) async {
    return await apiService.fetchWeeklyPlanPdfFile(planId, token);
  }
}