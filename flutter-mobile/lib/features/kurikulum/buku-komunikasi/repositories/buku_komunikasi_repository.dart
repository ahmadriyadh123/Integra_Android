import 'dart:io';

import 'package:http/http.dart' as http;

import '../local/buku_komunikasi_local_storage.dart';
import '../models/buku_komunikasi_model.dart';
import '../services/buku_komunikasi_service.dart';
import 'package:flutter_application_1/services/cache_scope.dart';

class BukuKomunikasiRepository {
  final BukuKomunikasiService apiService;
  final BukuKomunikasiLocalStorage localStorage;
  String? lastSyncError;

  BukuKomunikasiRepository({
    required this.apiService,
    required this.localStorage,
  });

  Future<BukuKomunikasiDetail?> getBukuKomunikasi(String token,
      {bool forceRefresh = false}) async {
    final scope = tokenCacheScope(token);
    final cached = await localStorage.loadBukuKomunikasi(scope: scope);
    if (!forceRefresh &&
        cached != null &&
        await localStorage.isBukuKomunikasiFresh(scope: scope)) {
      lastSyncError = null;
      return BukuKomunikasiDetail.fromJson(cached);
    }
    try {
      final data = await apiService.fetchBukuKomunikasi(token);
      await localStorage.saveBukuKomunikasi(data, scope: scope);
      lastSyncError = null;
      return data == null ? null : BukuKomunikasiDetail.fromJson(data);
    } catch (error) {
      lastSyncError = error.toString();
      if (cached != null) return BukuKomunikasiDetail.fromJson(cached);
      rethrow;
    }
  }

  Future<BukuKomunikasiSubmitStatus> submitDailyNote({
    required String token,
    required int lineId,
    required String day,
    required String noteText,
    String? month,
    int? week,
  }) async {
    try {
      final result = await apiService.submitDailyNote(
        token: token,
        lineId: lineId,
        day: day,
        noteText: noteText,
        month: month,
        week: week,
      );

      if (result) {
        await localStorage.clearCache(
          scope: tokenCacheScope(token),
        );
      }
      return result
          ? BukuKomunikasiSubmitStatus.submitted
          : BukuKomunikasiSubmitStatus.failed;
    } on SocketException {
      await localStorage.savePendingNote(
        lineId: lineId,
        day: day,
        noteText: noteText,
        month: month,
        week: week,
        scope: tokenCacheScope(token),
      );
      return BukuKomunikasiSubmitStatus.queued;
    } on HttpException {
      await localStorage.savePendingNote(
        lineId: lineId,
        day: day,
        noteText: noteText,
        month: month,
        week: week,
        scope: tokenCacheScope(token),
      );
      return BukuKomunikasiSubmitStatus.queued;
    } on http.ClientException {
      await localStorage.savePendingNote(
        lineId: lineId,
        day: day,
        noteText: noteText,
        month: month,
        week: week,
        scope: tokenCacheScope(token),
      );
      return BukuKomunikasiSubmitStatus.queued;
    } catch (_) {
      rethrow;
    }
  }
}
