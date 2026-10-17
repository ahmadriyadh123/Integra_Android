import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/user_friendly_error.dart';
import '../models/buku_komunikasi_model.dart';
import '../repositories/buku_komunikasi_repository.dart';

// Penanda apakah error berasal dari sesi yang tidak valid / token berakhir.
bool _isSessionError(String message) {
  final normalized = message.toLowerCase();
  return normalized.contains('sesi') ||
      normalized.contains('tidak valid') ||
      normalized.contains('berakhir') ||
      normalized.contains('login kembali') ||
      normalized.contains('unauthorized') ||
      normalized.contains('401');
}

class BukuKomunikasiViewModel extends ChangeNotifier {
  final BukuKomunikasiRepository repository;

  BukuKomunikasiViewModel({required this.repository});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;

  /// Pesan error yang sudah difilter agar aman ditampilkan ke user.
  String? get errorMessage =>
      _errorMessage == null ? null : userFriendlyError(_errorMessage!);

  /// True jika error terakhir disebabkan oleh sesi yang berakhir / token tidak
  /// valid — View dapat menggunakan ini untuk menampilkan pesan/aksi khusus.
  bool get isSessionExpired =>
      _errorMessage != null && _isSessionError(_errorMessage!);

  BukuKomunikasiDetail? _detail;
  BukuKomunikasiDetail? get detail => _detail;

  Future<void> fetchBukuKomunikasi(String token, {bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _detail = await repository.getBukuKomunikasi(token, forceRefresh: forceRefresh);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final status = await repository.submitDailyNote(
        token: token,
        lineId: lineId,
        day: day,
        noteText: noteText,
        month: month,
        week: week,
      );
      if (status == BukuKomunikasiSubmitStatus.submitted) {
        await fetchBukuKomunikasi(token, forceRefresh: true);
      }
      return status;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return BukuKomunikasiSubmitStatus.failed;
    } finally {
      _isLoading = false;
    }
  }
}