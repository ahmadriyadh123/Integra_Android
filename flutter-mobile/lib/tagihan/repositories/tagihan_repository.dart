import '../local/tagihan_local_storage.dart';
import '../models/tagihan_model.dart';
import '../services/tagihan_service.dart';

class TagihanRepository {
  final TagihanService apiService;
  final TagihanLocalStorage localStorage;

  TagihanRepository({
    required this.apiService,
    required this.localStorage,
  });

  /// Mengambil data ringkasan tagihan dengan strategi Cache-First dan fallback Offline.
  Future<TagihanSummary> getTagihan(String token, {String? paymentState, bool forceRefresh = false}) async {
    // 1. Coba baca dari cache lokal terlebih dahulu (jika tidak forceRefresh)
    if (!forceRefresh) {
      try {
        final cachedData = await localStorage.loadTagihanSummary(paymentState);
        if (cachedData != null) {
          return TagihanSummary.fromJson(cachedData);
        }
      } catch (_) {
        // Abaikan error cache, langsung fetch dari API
      }
    }

    // 2. Ambil dari API Odoo jika cache kosong/expired
    try {
      final data = await apiService.fetchTagihan(token, paymentState: paymentState);
      
      // Simpan ke cache lokal Hive
      await localStorage.saveTagihanSummary(paymentState, data);
      
      return TagihanSummary.fromJson(data);
    } catch (e) {
      // 3. Fallback offline: kembalikan cache terakhir jika ada
      try {
        final cachedData = await localStorage.loadTagihanSummary(paymentState);
        if (cachedData != null) {
          return TagihanSummary.fromJson(cachedData);
        }
      } catch (_) {}
      
      rethrow;
    }
  }
}
