import 'package:flutter/material.dart';
import '../models/assignment_model.dart';
import '../repositories/assignment_repository.dart';

enum AssignmentFilter { all, pending, submitted, graded }

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
  String? _activeToken;
  int _fetchRequestId = 0;

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
        if (!matchTitle && !matchSubject) {
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
  int get submittedCount =>
      _items.where((i) => i.isSubmitted && !i.isGraded).length;
  int get gradedCount => _items.where((i) => i.isGraded).length;

  Future<void> fetchAssignments(
    String token, {
    bool forceRefresh = false,
  }) async {
    final requestId = ++_fetchRequestId;
    if (_activeToken != token) {
      _activeToken = token;
      _items = [];
      _errorMessage = null;
      _isLoading = false;
      _isRefreshing = false;
      _currentFilter = AssignmentFilter.all;
      _searchQuery = '';
      notifyListeners();
    }
    _errorMessage = null;

    if (!forceRefresh) {
      List<Map<String, dynamic>>? cached;
      try {
        cached = await repository.loadCachedAssignments(token);
      } catch (e) {
        if (requestId != _fetchRequestId) return;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _isRefreshing = false;
        notifyListeners();
        return;
      }
      if (requestId != _fetchRequestId) return;
      if (cached != null && cached.isNotEmpty) {
        _items = cached.map((e) => AssignmentItem.fromJson(e)).toList();
        _isRefreshing = true;
        notifyListeners();

        try {
          final fresh = await repository.getAssignments(
            token,
            forceRefresh: true,
          );
          if (requestId != _fetchRequestId) return;
          _items = fresh;
        } catch (_) {
          if (requestId != _fetchRequestId) return;
        } finally {
          if (requestId == _fetchRequestId) {
            _isRefreshing = false;
            notifyListeners();
          }
        }
        return;
      }
    }

    _isLoading = true;
    notifyListeners();

    try {
      final fresh = await repository.getAssignments(
        token,
        forceRefresh: forceRefresh,
      );
      if (requestId != _fetchRequestId) return;
      _items = fresh;
    } catch (e) {
      if (requestId == _fetchRequestId) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
    } finally {
      if (requestId == _fetchRequestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<AssignmentItem> submitAssignment({
    required String token,
    required AssignmentItem assignment,
    required Stream<List<int>> fileStream,
    required int fileSize,
    required String fileName,
  }) async {
    final result = await repository.submitAssignment(
      token: token,
      assignmentId: assignment.id,
      fileStream: fileStream,
      fileSize: fileSize,
      fileName: fileName,
    );

    final submissionId = _parseResponseId(result['submission_id']);
    final attachmentId = _parseResponseId(result['attachment_id']);
    if (submissionId == null || attachmentId == null) {
      throw const FormatException(
        'Respons server tidak menyertakan riwayat berkas yang lengkap.',
      );
    }

    final existingItem = _items
        .where((item) => item.id == assignment.id)
        .firstOrNull;
    final itemToUpdate = existingItem ?? assignment;
    final submittedAt = DateTime.tryParse(
      result['submitted_at']?.toString() ?? '',
    );
    final uploadedAttachment = AttachmentItem(
      id: attachmentId,
      fileName: result['file_name']?.toString() ?? fileName,
      fileUrl: '/assignments/${assignment.id}/attachments/$attachmentId',
      uploadedByRole: 'student',
    );
    final currentSubmission = itemToUpdate.studentSubmission;
    final attachments = [
      ...?currentSubmission?.attachments.where(
        (attachment) => attachment.id != attachmentId,
      ),
      uploadedAttachment,
    ];
    final updatedSubmission = StudentSubmission(
      id: submissionId,
      state: result['state']?.toString() ?? 'submitted',
      marks: currentSubmission?.marks ?? 0,
      submittedAt: submittedAt ?? DateTime.now(),
      attachments: attachments,
    );
    final updatedItem = itemToUpdate.copyWith(
      studentSubmission: updatedSubmission,
    );

    if (_activeToken == null || _activeToken == token) {
      _items = [
        for (final item in _items)
          if (item.id == assignment.id) updatedItem else item,
        if (existingItem == null) updatedItem,
      ];
      await repository.saveCachedAssignments(
        _items.map((item) => item.toJson()).toList(),
        token: token,
      );
      notifyListeners();
    }
    return updatedItem;
  }

  int? _parseResponseId(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');

  void setFilter(AssignmentFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void reset() {
    _fetchRequestId++;
    _activeToken = null;
    _items = [];
    _errorMessage = null;
    _isLoading = false;
    _isRefreshing = false;
    _currentFilter = AssignmentFilter.all;
    _searchQuery = '';
  }
}
