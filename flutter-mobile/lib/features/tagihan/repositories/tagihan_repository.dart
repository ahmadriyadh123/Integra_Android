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
    // Gunakan cache yang masih berlaku kecuali refresh dipaksa.
    if (!forceRefresh) {
      try {
        final cachedData = await localStorage.loadTagihanSummary(paymentState);
        if (cachedData != null) {
          return TagihanSummary.fromJson(cachedData);
        }
      } catch (_) {
        // Cache yang rusak tidak boleh menghentikan pengambilan data baru.
      }
    }

    // Ambil data baru saat cache kosong atau sudah kedaluwarsa.
    try {
      final data = await apiService.fetchTagihan(token, paymentState: paymentState);
      
      // Simpan response agar halaman tetap tersedia saat offline.
      await localStorage.saveTagihanSummary(paymentState, data);
      
      return TagihanSummary.fromJson(data);
    } catch (e) {
      // Saat API gagal, gunakan cache terakhir sebagai fallback offline.
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
