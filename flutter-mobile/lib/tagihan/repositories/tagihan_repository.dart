import '../models/tagihan_model.dart';
import '../services/tagihan_service.dart';

class TagihanRepository {
  final TagihanService apiService;

  TagihanRepository({required this.apiService});

  Future<TagihanSummary> getTagihan(String token, {String? paymentState}) async {
    final data = await apiService.fetchTagihan(token, paymentState: paymentState);
    return TagihanSummary.fromJson(data);
  }
}
