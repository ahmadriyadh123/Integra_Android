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

  /// Mengambil data ringkasan tagihan dengan strategi Cache-First dan fallback Offline.
  Future<TagihanSummary> getTagihan(String token, {String? paymentState, bool forceRefresh = false}) async {
    final scope = tokenCacheScope(token);
    final cachedData = await localStorage.loadTagihanSummary(
      paymentState,
      scope: scope,
    );

    // Ambil data baru saat cache kosong atau sudah kedaluwarsa.
    try {
      final data = await apiService.fetchTagihan(token, paymentState: paymentState);
      
      // Simpan response agar halaman tetap tersedia saat offline.
      await localStorage.saveTagihanSummary(
        paymentState,
        data,
        scope: scope,
      );
      lastSyncError = null;
      return TagihanSummary.fromJson(data);
    } catch (e) {
      lastSyncError = e.toString();
      if (cachedData != null) return TagihanSummary.fromJson(cachedData);
      rethrow;
    }
  }
}
