import '../local/buku_komunikasi_local_storage.dart';
import '../models/buku_komunikasi_model.dart';
import '../services/buku_komunikasi_service.dart';

class BukuKomunikasiRepository {
  final BukuKomunikasiService apiService;
  final BukuKomunikasiLocalStorage localStorage;

  BukuKomunikasiRepository({
    required this.apiService,
    required this.localStorage,
  });

  Future<BukuKomunikasiDetail?> getBukuKomunikasi(String token,
      {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await localStorage.loadBukuKomunikasi();
      if (cached != null) {
        return BukuKomunikasiDetail.fromJson(cached);
      }
    }

    final data = await apiService.fetchBukuKomunikasi(token);
    if (data == null) return null;

    await localStorage.saveBukuKomunikasi(data);
    return BukuKomunikasiDetail.fromJson(data);
  }

  Future<bool> submitDailyNote({
      required String token,
      required int lineId,
      required String day,
      required String noteText,
    }) async {
      final result = await apiService.submitDailyNote(
        token: token,
        lineId: lineId,
        day: day,
        noteText: noteText,
      );
      if (result) {
        await localStorage.clearCache();
      }
      return result;
  }
}
