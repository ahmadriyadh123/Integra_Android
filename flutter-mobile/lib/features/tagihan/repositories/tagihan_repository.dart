import '../local/tagihan_local_storage.dart';
import '../models/tagihan_model.dart';
import '../services/tagihan_service.dart';
import 'package:flutter_application_1/services/cache_scope.dart';

class TagihanRepository {
  final TagihanService apiService;
  final TagihanLocalStorage localStorage;
  String? lastSyncError;

  TagihanRepository({
    required this.apiService,
    required this.localStorage,
  });

  /// Baca cache saja (tanpa TTL check) — dipakai SWR phase 1.
  Future<TagihanSummary?> loadCachedTagihan(
    String token, {
    String? paymentState,
  }) async {
    final scope = tokenCacheScope(token);
    final raw = await localStorage.loadTagihanSummary(paymentState, scope: scope);
    if (raw == null) return null;
    try {
      return TagihanSummary.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  /// Sync delta: hanya ambil yang berubah sejak cursor, merge ke cache lokal.
  /// Jika cursor null → full sync.
  Future<TagihanSummary> getTagihan(
    String token, {
    String? paymentState,
    bool forceRefresh = false,
  }) async {
    final scope = tokenCacheScope(token);

    // Baca cache lokal
    final cached = await localStorage.loadTagihanSummary(paymentState, scope: scope);
    final cursor = await localStorage.loadCursor(scope);

    // Jika cache masih fresh dan tidak force, kembalikan cache
    if (!forceRefresh &&
        cached != null &&
        await localStorage.isTagihanSummaryFresh(paymentState, scope: scope)) {
      lastSyncError = null;
      return TagihanSummary.fromJson(cached);
    }

    try {
      // Delta sync: kirim cursor agar server hanya membalas tagihan baru/berubah
      // (create_date/write_date >= cursor). Full sync hanya jika cursor hilang
      // atau sudah lewat window 24 jam — BUKAN karena forceRefresh (swipe).
      final fullSyncAt = await localStorage.loadFullSyncAt(scope);
      final fullSyncDue = fullSyncAt == null ||
          DateTime.now().difference(
                DateTime.fromMillisecondsSinceEpoch(fullSyncAt),
              ) >=
              TagihanLocalStorage.fullSyncInterval;
      final usedCursor = cursor == null || cursor.isEmpty || fullSyncDue ? null : cursor;

      final syncResult = await apiService.syncTagihan(
        token,
        cursor: usedCursor,
      );

      final nextCursor = syncResult['next_cursor'] as String?;
      final isFullSync = syncResult['full_sync'] as bool? ?? usedCursor == null;
      final rawItems = syncResult['items'] as List<dynamic>? ?? [];
      final allActiveIds = (syncResult['all_active_ids'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toSet();

      // Bangun map dari cache lokal yang sudah ada
      final mergedMap = <int, Map<String, dynamic>>{};

      if (!isFullSync && cached != null) {
        // Pertahankan data lama
        final cachedInvoices = cached['invoices'] as List<dynamic>? ?? [];
        for (final item in cachedInvoices) {
          if (item is Map) {
            final id = item['id'] as int?;
            if (id != null) mergedMap[id] = Map<String, dynamic>.from(item);
          }
        }
        // Hapus ID yang tidak lagi aktif di server
        if (allActiveIds != null) {
          mergedMap.removeWhere((id, _) => !allActiveIds.contains(id));
        }
      }

      // Merge item baru/berubah
      for (final item in rawItems) {
        if (item is Map) {
          final id = item['id'] as int?;
          if (id != null) mergedMap[id] = Map<String, dynamic>.from(item);
        }
      }

      // Hitung ulang total
      double totalUnpaid = 0.0;
      for (final item in mergedMap.values) {
        final residual = (item['residual_amount'] as num?)?.toDouble() ?? 0.0;
        totalUnpaid += residual;
      }

      final mergedData = {
        'total_unpaid_amount': totalUnpaid,
        'total_invoices': mergedMap.length,
        'invoices': mergedMap.values.toList(),
      };

      // Simpan ke cache dengan cursor baru
      await localStorage.saveTagihanSummary(
        paymentState,
        mergedData,
        scope: scope,
        cursor: nextCursor,
      );
      if (isFullSync) {
        await localStorage.saveFullSyncAt(
          scope,
          DateTime.now().millisecondsSinceEpoch,
        );
      }
      lastSyncError = null;
      return TagihanSummary.fromJson(mergedData);
    } catch (e) {
      lastSyncError = e.toString();
      if (cached != null) return TagihanSummary.fromJson(cached);
      rethrow;
    }
  }
}
