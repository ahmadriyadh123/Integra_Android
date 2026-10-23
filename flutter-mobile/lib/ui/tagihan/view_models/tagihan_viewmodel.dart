import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/services/core/stale_while_revalidate.dart';
import 'package:flutter_application_1/utils/user_friendly_error.dart';
import '../../../data/model/tagihan/tagihan_model.dart';
import '../../../data/repositories/tagihan/tagihan_repository.dart';

class TagihanViewModel extends ChangeNotifier with StaleWhileRevalidateMixin {
  final TagihanRepository repository;

  TagihanViewModel({required this.repository});

  // isLoading dan isRefreshing disediakan oleh StaleWhileRevalidateMixin

  String? _errorMessage;
  String? get errorMessage =>
      _errorMessage == null ? null : userFriendlyError(_errorMessage!);

  TagihanSummary? _summary;
  TagihanSummary? get summary => _summary;

  bool get hasData => _summary != null;

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

  Future<void> fetchTagihan(String token, {bool forceRefresh = false}) =>
      swr<TagihanSummary>(
        hasStale: _summary != null,
        forceRefresh: forceRefresh,
        load: () => repository.loadCachedTagihan(token),
        fetch: () => repository.getTagihan(token, forceRefresh: true),
        onData: (data) {
          _summary = data;
          _errorMessage = null;
        },
        onError: (e) {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        },
      );

  void reset() {
    _summary = null;
    _errorMessage = null;
    _selectedFilter = 'Semua';
  }
}
