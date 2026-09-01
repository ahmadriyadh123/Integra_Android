import 'package:flutter/material.dart';
import '../models/assignment_model.dart';
import '../repositories/assignment_repository.dart';

enum AssignmentFilter {
  all,
  pending,
  submitted,
  graded,
}

class AssignmentViewModel extends ChangeNotifier {
  final AssignmentRepository repository;

  AssignmentViewModel({required this.repository});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<AssignmentItem> _items = [];
  List<AssignmentItem> get items => _items;

  AssignmentFilter _currentFilter = AssignmentFilter.all;
  AssignmentFilter get currentFilter => _currentFilter;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<AssignmentItem> get filteredItems {
    return _items.where((item) {
      // 1. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(query);
        final matchSubject = item.subject.name.toLowerCase().contains(query);
        final matchType = item.assignmentType.toLowerCase().contains(query);
        if (!matchTitle && !matchSubject && !matchType) {
          return false;
        }
      }

      // 2. Status Filter
      switch (_currentFilter) {
        case AssignmentFilter.pending:
          return !item.isSubmitted;
        case AssignmentFilter.submitted:
          return item.isSubmitted && !item.isGraded;
        case AssignmentFilter.graded:
          return item.isGraded;
        case AssignmentFilter.all:
        default:
          return true;
      }
    }).toList();
  }

  int get pendingCount => _items.where((i) => !i.isSubmitted).length;
  int get submittedCount => _items.where((i) => i.isSubmitted && !i.isGraded).length;
  int get gradedCount => _items.where((i) => i.isGraded).length;

  Future<void> fetchAssignments(String token, {bool forceRefresh = false}) async {
    _errorMessage = null;

    if (!forceRefresh) {
      final cached = await repository.loadCachedAssignments();
      if (cached != null && cached.isNotEmpty) {
        _items = cached.map((e) => AssignmentItem.fromJson(e)).toList();
        _isRefreshing = true;
        notifyListeners();

        try {
          final fresh = await repository.getAssignments(token, forceRefresh: true);
          _items = fresh;
        } catch (_) {
          // Gagal background refresh - pertahankan cache
        } finally {
          _isRefreshing = false;
          notifyListeners();
        }
        return;
      }
    }

    _isLoading = true;
    notifyListeners();

    try {
      final fresh = await repository.getAssignments(token, forceRefresh: forceRefresh);
      _items = fresh;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(AssignmentFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void reset() {
    _items = [];
    _errorMessage = null;
    _isLoading = false;
    _isRefreshing = false;
    _currentFilter = AssignmentFilter.all;
    _searchQuery = '';
  }
}
