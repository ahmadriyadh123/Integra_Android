import 'dart:typed_data';
import '../local/rapor_local_storage.dart';
import '../models/rapor_model.dart';
import '../services/rapor_service.dart';
import '../services/rapor_pdf_generator_service.dart';
import '../../auth/models/auth_model.dart';
import 'package:flutter_application_1/services/cache_scope.dart';

class RaporRepository {
  final RaporService apiService;
  final RaporLocalStorage localStorage;
  String? lastSyncError;

  RaporRepository({
    required this.apiService,
    required this.localStorage,
  });

  /// Kembalikan URL endpoint PDF — langsung di-stream oleh middleware
  String getPdfUrl(int raporId) {
    return '${apiService.baseUrl}/e-rapor/pdf/$raporId';
  }

  Future<Uint8List> generatePdf(
    ReportCardDetail detail,
    ReportCardHeader? header,
    UserProfile? user,
  ) {
    return RaporPdfGeneratorService.generateRaporPdf(detail, header, user);
  }

  Future<List<ReportCardHeader>> getReportList(String token,
      {bool forceRefresh = false}) async {
    final scope = tokenCacheScope(token);
    final snapshot = await localStorage.loadRaporListSnapshot(scope: scope);
    final rawCached = snapshot?['items'];
    final cached = rawCached is List ? rawCached : null;
    final cursor = snapshot?['cursor'];
    final fullSyncAt = snapshot?['full_sync_at'];
    final fullSync =
        forceRefresh ||
        cached == null ||
        cursor is! String ||
        cursor.isEmpty ||
        fullSyncAt is! int ||
        DateTime.now().difference(
              DateTime.fromMillisecondsSinceEpoch(fullSyncAt),
            ) >=
            RaporLocalStorage.fullSyncInterval;
    try {
      final result = await apiService.syncReportList(
        token,
        cursor: fullSync ? null : cursor,
      );
      final rawItems = result['items'];
      final rawRemovedIds = result['removed_ids'];
      final nextCursor = result['next_cursor'];
      final serverFullSync = result['full_sync'];
      if (rawItems is! List ||
          rawRemovedIds is! List ||
          nextCursor is! String ||
          nextCursor.isEmpty ||
          serverFullSync is! bool ||
          (fullSync && !serverFullSync)) {
        throw const FormatException(
          'Respons sinkronisasi daftar E-Rapor tidak lengkap.',
        );
      }
      final merged = <int, Map<String, dynamic>>{};
      if (!serverFullSync && cached != null) {
        for (final value in cached) {
          if (value is! Map) {
            throw const FormatException('Snapshot daftar E-Rapor tidak valid.');
          }
          final item = Map<String, dynamic>.from(value);
          final id = _parseReportId(item['id']);
          if (id == null) {
            throw const FormatException('ID cache E-Rapor tidak valid.');
          }
          merged[id] = item;
        }
      }
      for (final value in rawRemovedIds) {
        final id = _parseReportId(value);
        if (id == null) {
          throw const FormatException('ID E-Rapor yang dihapus tidak valid.');
        }
        merged.remove(id);
      }
      for (final value in rawItems) {
        if (value is! Map) {
          throw const FormatException('Record E-Rapor tidak valid.');
        }
        final item = Map<String, dynamic>.from(value);
        final id = _parseReportId(item['id']);
        if (id == null) {
          throw const FormatException('ID E-Rapor tidak valid.');
        }
        merged[id] = item;
      }
      final data = merged.values.toList();
      await localStorage.saveRaporList(
        data,
        scope: scope,
        cursor: nextCursor,
        fullSyncAt: serverFullSync
            ? DateTime.now().millisecondsSinceEpoch
            : fullSyncAt as int?,
      );
      lastSyncError = null;
      return data.map(ReportCardHeader.fromJson).toList();
    } catch (error) {
      lastSyncError = error.toString();
      if (cached != null) {
        return cached
            .map(
              (value) => ReportCardHeader.fromJson(
                Map<String, dynamic>.from(value as Map),
              ),
            )
            .toList();
      }
      rethrow;
    }
  }

  int? _parseReportId(dynamic value) {
    if (value is int && value > 0) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  Future<ReportCardDetail> getReportDetail(String token, int raporId,
      {bool forceRefresh = false}) async {
    final scope = tokenCacheScope(token);
    final cached = await localStorage.loadRaporDetail(raporId, scope: scope);
    try {
      final data = await apiService.fetchReportDetail(token, raporId);
      final detail = ReportCardDetail.fromJson(data);
      await localStorage.saveRaporDetail(raporId, data, scope: scope);
      lastSyncError = null;
      return detail;
    } catch (error) {
      lastSyncError = error.toString();
      if (cached != null) {
        return ReportCardDetail.fromJson(Map<String, dynamic>.from(cached));
      }
      rethrow;
    }
  }
}
