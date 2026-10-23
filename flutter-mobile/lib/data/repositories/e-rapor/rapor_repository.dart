import 'dart:typed_data';
import '../../local/e-rapor/rapor_local_storage.dart';
import '../../model/e-rapor/rapor_model.dart';
import '../../services/e-rapor/rapor_service.dart';
import '../../services/e-rapor/rapor_pdf_generator_service.dart';
import '../../model/auth/auth_model.dart';
import 'package:flutter_application_1/data/local/cache_scope.dart';

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

  /// Baca daftar rapor dari cache saja (tanpa TTL check) — dipakai SWR phase 1.
  Future<List<ReportCardHeader>?> loadCachedReportList(String token) async {
    final scope = tokenCacheScope(token);
    final snapshot = await localStorage.loadRaporListSnapshot(scope: scope);
    final rawCached = snapshot?['items'];
    if (rawCached is! List || rawCached.isEmpty) return null;
    try {
      return rawCached
          .map((v) => ReportCardHeader.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Baca detail rapor dari cache saja — dipakai SWR phase 1.
  Future<ReportCardDetail?> loadCachedReportDetail(String token, int raporId) async {
    final cached = await localStorage.loadRaporDetail(raporId, scope: tokenCacheScope(token));
    if (cached == null) return null;
    try {
      return ReportCardDetail.fromJson(Map<String, dynamic>.from(cached));
    } catch (_) {
      return null;
    }
  }

  Future<List<ReportCardHeader>> getReportList(String token,
      {bool forceRefresh = false}) async {
    final scope = tokenCacheScope(token);
    final snapshot = await localStorage.loadRaporListSnapshot(scope: scope);
    final rawCached = snapshot?['items'];
    final cached = rawCached is List ? rawCached : null;
    if (cached != null && !forceRefresh) {
      lastSyncError = null;
      return cached
          .map(
            (value) => ReportCardHeader.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList();
    }
    final cursor = snapshot?['cursor'];
    final fullSyncAt = snapshot?['full_sync_at'];
    final fullSync =
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
    if (cached != null && !forceRefresh) {
      lastSyncError = null;
      return ReportCardDetail.fromJson(Map<String, dynamic>.from(cached));
    }
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

  Future<Uint8List?> loadCachedReportPdf(String token, int raporId) {
    return localStorage.loadRaporPdf(
      raporId,
      scope: tokenCacheScope(token),
    );
  }

  Future<Uint8List> getReportPdf(
    String token,
    int raporId, {
    bool forceRefresh = false,
  }) async {
    final scope = tokenCacheScope(token);
    final cached = await localStorage.loadRaporPdf(raporId, scope: scope);
    if (cached != null && !forceRefresh) return cached;

    final pdfBytes = await apiService.fetchReportPdf(token, raporId);
    await localStorage.saveRaporPdf(raporId, pdfBytes, scope: scope);
    return pdfBytes;
  }

  Future<void> saveReportPdf(
    String token,
    int raporId,
    Uint8List pdfBytes,
  ) {
    return localStorage.saveRaporPdf(
      raporId,
      pdfBytes,
      scope: tokenCacheScope(token),
    );
  }
}
