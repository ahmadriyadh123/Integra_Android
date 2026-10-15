import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/user_friendly_error.dart';
import '../models/tagihan_model.dart';
import '../repositories/tagihan_repository.dart';

class TagihanViewModel extends ChangeNotifier {
  final TagihanRepository repository;

  TagihanViewModel({required this.repository});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage =>
      _errorMessage == null ? null : userFriendlyError(_errorMessage!);

  TagihanSummary? _summary;
  TagihanSummary? get summary => _summary;

  bool get hasData => _summary != null;

  // Filter aktif: 'Semua', 'Belum Lunas', 'Lunas'
  String _selectedFilter = 'Semua';
  String get selectedFilter => _selectedFilter;

  List<InvoiceItem> get filteredInvoices {
    if (_summary == null) return [];
    switch (_selectedFilter) {
      case 'Belum Lunas':
        return _summary!.invoices
            .where((i) => i.paymentState != 'paid')
            .toList();
      case 'Lunas':
        return _summary!.invoices
            .where((i) => i.paymentState == 'paid')
            .toList();
      default:
        return _summary!.invoices;
    }
  }

  int get unpaidCount =>
      _summary?.invoices.where((i) => i.paymentState != 'paid').length ?? 0;

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<void> fetchTagihan(String token, {bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await repository.getTagihan(token, forceRefresh: forceRefresh);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _summary = null;
    _errorMessage = null;
    _isLoading = false;
    _selectedFilter = 'Semua';
  }
}
