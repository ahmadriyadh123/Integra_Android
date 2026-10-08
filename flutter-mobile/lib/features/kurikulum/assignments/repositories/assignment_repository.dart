import 'dart:convert';

import '../local/assignment_local_storage.dart';
import '../models/assignment_model.dart';
import '../services/assignment_service.dart';

class AssignmentRepository {
  final AssignmentService apiService;
  final AssignmentLocalStorage localStorage;

  AssignmentRepository({required this.apiService, required this.localStorage});

  Future<List<AssignmentItem>> getAssignments(
    String token, {
    bool forceRefresh = false,
  }) async {
    final cacheScope = cacheScopeForToken(token);
    if (!forceRefresh) {
      final cached = await localStorage.loadAssignments(
        cacheScope: cacheScope,
      );
      if (cached != null && cached.isNotEmpty) {
        return cached.map((e) => AssignmentItem.fromJson(e)).toList();
      }
    }

    final rawData = await apiService.fetchAssignments(token);
    await localStorage.saveAssignments(rawData, cacheScope: cacheScope);
    return rawData.map((e) => AssignmentItem.fromJson(e)).toList();
  }

  String cacheScopeForToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException('Token login tidak valid untuk cache tugas.');
    }

    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map<String, dynamic>) {
        throw const FormatException();
      }

      final schoolId = _parseId(payload['school_id']);
      final userId = _parseId(payload['uid']);
      if (schoolId == null || userId == null) {
        throw const FormatException();
      }
      return 'school_${schoolId}_user_$userId';
    } on FormatException {
      throw const FormatException(
        'Token login tidak memiliki identitas sekolah dan pengguna yang valid.',
      );
    }
  }

  int? _parseId(dynamic value) {
    if (value is int && value > 0) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  Future<Map<String, dynamic>> submitAssignment({
    required String token,
    required int assignmentId,
    required Stream<List<int>> fileStream,
    required int fileSize,
    required String fileName,
  }) {
    return apiService.submitAssignment(
      token: token,
      assignmentId: assignmentId,
      fileStream: fileStream,
      fileSize: fileSize,
      fileName: fileName,
    );
  }

  Future<List<Map<String, dynamic>>?> loadCachedAssignments(String token) {
    return localStorage.loadAssignments(
      cacheScope: cacheScopeForToken(token),
    );
  }

  Future<void> saveCachedAssignments(
    List<Map<String, dynamic>> data, {
    required String token,
  }) {
    return localStorage.saveAssignments(
      data,
      cacheScope: cacheScopeForToken(token),
    );
  }

  Future<void> clearCache(String token) {
    return localStorage.clear(cacheScope: cacheScopeForToken(token));
  }
}
