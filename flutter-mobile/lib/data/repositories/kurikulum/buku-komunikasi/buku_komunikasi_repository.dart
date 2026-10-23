import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../local/kurikulum/buku-komunikasi/buku_komunikasi_local_storage.dart';
import '../../../model/kurikulum/buku-komunikasi/buku_komunikasi_model.dart';
import '../../../services/kurikulum/buku-komunikasi/buku_komunikasi_service.dart';
import 'package:flutter_application_1/data/local/cache_scope.dart';

class BukuKomunikasiRepository {
  final BukuKomunikasiService apiService;
  final BukuKomunikasiLocalStorage localStorage;
  String? lastSyncError;

  BukuKomunikasiRepository({
    required this.apiService,
    required this.localStorage,
  });

  /// Baca cache saja tanpa TTL check — dipakai SWR phase 1.
  Future<BukuKomunikasiDetail?> loadCachedBukuKomunikasi(String token) async {
    final raw = await localStorage.loadBukuKomunikasi(
      scope: tokenCacheScope(token),
    );
    if (raw == null) return null;
    try {
      return BukuKomunikasiDetail.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  Future<BukuKomunikasiDetail?> getBukuKomunikasi(String token,
      {bool forceRefresh = false}) async {
    final scope = tokenCacheScope(token);
    final cached = await localStorage.loadBukuKomunikasi(scope: scope);

    // Jika cache masih fresh dan tidak dipaksa refresh, kembalikan cache
    if (!forceRefresh &&
        cached != null &&
        await localStorage.isBukuKomunikasiFresh(scope: scope)) {
      lastSyncError = null;
      return BukuKomunikasiDetail.fromJson(cached);
    }

    try {
      // Delta sync: kirim cursor agar server hanya membalas data yang berubah
      // (create_date/write_date >= cursor). Full sync hanya jika cursor hilang
      // atau sudah lewat window 24 jam — BUKAN karena forceRefresh (swipe).
      final cursor = await localStorage.loadCursor(scope: scope);
      final fullSyncAt = await localStorage.loadFullSyncAt(scope: scope);
      final fullSyncDue = fullSyncAt == null ||
          DateTime.now().difference(
                DateTime.fromMillisecondsSinceEpoch(fullSyncAt),
              ) >=
              BukuKomunikasiLocalStorage.fullSyncInterval;
      final fullSync = cursor == null || cursor.isEmpty || fullSyncDue;

      final syncResult = await apiService.syncBukuKomunikasi(
        token,
        cursor: fullSync ? null : cursor,
      );

      final nextCursor = syncResult['next_cursor'] as String?;
      final isFullSync = syncResult['full_sync'] as bool? ?? fullSync;
      final rawItems = syncResult['items'] as List<dynamic>? ?? [];
      final allActiveIds = (syncResult['all_active_ids'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toSet();

      // Mulai dari cache yang sudah ada
      Map<String, dynamic>? mergedDetail;
      final mergedLines = <int, Map<String, dynamic>>{};

      if (!isFullSync && cached != null) {
        mergedDetail = Map<String, dynamic>.from(cached);
        final cachedLines = cached['lines'] as List<dynamic>? ?? [];
        for (final line in cachedLines) {
          if (line is Map) {
            final id = line['id'] as int?;
            if (id != null) mergedLines[id] = Map<String, dynamic>.from(line);
          }
        }
        // Hapus ID yang tidak lagi aktif di server
        if (allActiveIds != null) {
          mergedLines.removeWhere((id, _) => !allActiveIds.contains(id));
        }
      }

      // Merge item baru/berubah
      for (final item in rawItems) {
        if (item is Map) {
          final id = item['id'] as int?;
          if (id != null) mergedLines[id] = Map<String, dynamic>.from(item);
        }
      }

      // Urutkan berdasarkan pekan_ke lalu id
      final sortedLines = mergedLines.values.toList()
        ..sort((a, b) {
          final pa = (a['pekan_ke'] as int?) ?? 1;
          final pb = (b['pekan_ke'] as int?) ?? 1;
          final cmp = pa.compareTo(pb);
          return cmp != 0 ? cmp : ((a['id'] as int?) ?? 0).compareTo((b['id'] as int?) ?? 0);
        });

      // Bangun detail final
      if (mergedDetail == null) {
        // Full sync — ambil header dari response jika ada, atau buat minimal
        final headerId = syncResult['header_id'] as int?;
        mergedDetail = {
          'id': headerId ?? 0,
          'student_name': syncResult['student_name'] ?? cached?['student_name'] ?? '-',
          'kelas': syncResult['kelas'] ?? cached?['kelas'] ?? '-',
          'tahun_ajaran': syncResult['tahun_ajaran'] ?? cached?['tahun_ajaran'] ?? '-',
          'status': syncResult['status'] ?? cached?['status'] ?? '-',
        };
      }
      mergedDetail['lines'] = sortedLines;

      // Simpan ke cache
      await localStorage.saveBukuKomunikasi(mergedDetail, scope: scope);
      if (nextCursor != null) {
        await localStorage.saveCursor(nextCursor, scope: scope);
      }
      if (isFullSync) {
        await localStorage.saveFullSyncAt(
          DateTime.now().millisecondsSinceEpoch,
          scope: scope,
        );
      }

      lastSyncError = null;
      return BukuKomunikasiDetail.fromJson(mergedDetail);
    } catch (error) {
      lastSyncError = error.toString();
      if (cached != null) return BukuKomunikasiDetail.fromJson(cached);
      rethrow;
    }
  }

  Future<int> pendingNoteCount(String token) async {
    final notes = await localStorage.loadPendingNotes(
      scope: tokenCacheScope(token),
    );
    return notes.length;
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

  /// Kirim ulang semua catatan yang antre di Hive ke server.
  ///
  /// Strategi: kirim satu per satu secara berurutan. Jika berhasil, hapus
  /// langsung dari queue (by index). Jika gagal karena jaringan, berhenti
  /// dan biarkan sisanya tetap di queue untuk dicoba lagi nanti.
  /// Kembalikan jumlah catatan yang berhasil terkirim.
  Future<int> syncPendingNotes(String token) async {
    final scope = tokenCacheScope(token);
    final pending = await localStorage.loadPendingNotes(scope: scope);
    if (pending.isEmpty) return 0;

    int synced = 0;
    // Iterasi dari belakang agar index tidak bergeser saat hapus
    for (int i = pending.length - 1; i >= 0; i--) {
      final note = pending[i];
      try {
        final result = await apiService.submitDailyNote(
          token: token,
          lineId: (note['line_id'] as num).toInt(),
          day: note['day'] as String,
          noteText: note['note_text'] as String,
          month: note['month'] as String?,
          week: note['week'] != null ? (note['week'] as num).toInt() : null,
        );
        if (result) {
          await localStorage.removePendingNoteAt(i, scope: scope);
          synced++;
        }
      } on SocketException {
        // Jaringan masih tidak ada — hentikan, coba lagi nanti
        break;
      } on HttpException {
        break;
      } on http.ClientException {
        break;
      } catch (_) {
        // Error lain (server 4xx/5xx) — lewati item ini, lanjut ke berikutnya
        continue;
      }
    }

    if (synced > 0) {
      // Hapus cache agar data terbaru diambil dari server
      await localStorage.clearCache(scope: scope);
    }
    return synced;
  }
}
