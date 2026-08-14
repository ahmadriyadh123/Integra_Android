import 'package:flutter/material.dart';
import '../models/buku_komunikasi_model.dart';
import '../repositories/buku_komunikasi_repository.dart';

class BukuKomunikasiViewModel extends ChangeNotifier {
  final BukuKomunikasiRepository repository;

  BukuKomunikasiViewModel({required this.repository});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  BukuKomunikasiDetail? _detail;
  BukuKomunikasiDetail? get detail => _detail;

  Future<void> fetchBukuKomunikasi(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _detail = await repository.getBukuKomunikasi(token);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitFeedback({
    required String token,
    required int lineId,
    required String day,
    required String feedbackText,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await repository.submitFeedback(
        token: token,
        lineId: lineId,
        day: day,
        feedbackText: feedbackText,
      );
      if (success) {
        // Refresh data to get the latest parent feedback
        await fetchBukuKomunikasi(token);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }
}
