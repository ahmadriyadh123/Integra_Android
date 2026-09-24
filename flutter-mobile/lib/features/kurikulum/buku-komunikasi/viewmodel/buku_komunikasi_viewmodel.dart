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

  Future<void> fetchBukuKomunikasi(String token, {bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _detail = await repository.getBukuKomunikasi(token, forceRefresh: forceRefresh);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitDailyNote({
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
      final success = await repository.submitDailyNote(
        token: token,
        lineId: lineId,
        day: day,
        noteText: noteText,
        month: month,
        week: week,
      );
      if (success) {
        await fetchBukuKomunikasi(token, forceRefresh: true); // Paksa fetch ulang langsung ke API
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