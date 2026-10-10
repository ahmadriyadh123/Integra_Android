import 'dart:io';

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

  Future<bool> submitDailyNote({
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
      return result;
    } on SocketException catch (_) {
      await localStorage.savePendingNote(
        lineId: lineId,
        day: day,
        noteText: noteText,
        month: month,
        week: week,
        scope: tokenCacheScope(token),
      );
      return true;
    } on HttpException catch (_) {
      await localStorage.savePendingNote(
        lineId: lineId,
        day: day,
        noteText: noteText,
        month: month,
        week: week,
        scope: tokenCacheScope(token),
      );
      return true;
    } catch (_) {
      rethrow;
    }
  }
}
