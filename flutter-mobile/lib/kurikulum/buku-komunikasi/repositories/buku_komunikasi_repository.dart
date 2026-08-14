import '../models/buku_komunikasi_model.dart';
import '../services/buku_komunikasi_service.dart';

class BukuKomunikasiRepository {
  final BukuKomunikasiService apiService;

  BukuKomunikasiRepository({required this.apiService});

  Future<BukuKomunikasiDetail?> getBukuKomunikasi(String token) async {
    final data = await apiService.fetchBukuKomunikasi(token);
    if (data == null) return null;
    return BukuKomunikasiDetail.fromJson(data);
  }

  Future<bool> submitFeedback({
    required String token,
    required int lineId,
    required String day,
    required String feedbackText,
  }) async {
    return apiService.submitFeedback(
      token: token,
      lineId: lineId,
      day: day,
      feedbackText: feedbackText,
    );
  }
}
