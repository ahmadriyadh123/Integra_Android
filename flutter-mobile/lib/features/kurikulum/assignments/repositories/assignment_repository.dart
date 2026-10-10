import 'dart:convert';

import '../local/assignment_local_storage.dart';
import '../models/assignment_model.dart';
import '../services/assignment_service.dart';

class AssignmentRepository {
  final AssignmentService apiService;
  final AssignmentLocalStorage localStorage;
  String? lastSyncError;

  AssignmentRepository({required this.apiService, required this.localStorage});

  Future<List<AssignmentItem>> getAssignments(
    String token, {
    bool forceRefresh = false,
  }) async {
    final cacheScope = cacheScopeForToken(token);
    final snapshot = await localStorage.loadAssignmentSnapshot(
      cacheScope: cacheScope,
    );
    final rawCached = snapshot?['items'];
    final cached = rawCached is List
        ? rawCached
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : null;
    final cursor = snapshot?['cursor'];
    final fullSyncAt = snapshot?['full_sync_at'];
    final fullSync =
        forceRefresh ||
        cached == null ||
        cursor is! String ||
        cursor.isEmpty ||
        fullSyncAt is! int ||
        DateTime.now().difference(
              DateTime.fromMillisecondsSinceEpoch(fullSyncAt),
            ) >=
            AssignmentLocalStorage.fullSyncInterval;
    try {
      final result = await apiService.syncAssignments(
        token,
        cursor: fullSync ? null : cursor,
      );
      final rawItems = result['items'];
      final rawRemovedIds = result['removed_ids'];
      final nextCursor = result['next_cursor'];
      final serverFullSync = result['full_sync'];
      if (rawItems is! List ||
          rawRemovedIds is! List ||
          nextCursor is! String ||
          nextCursor.isEmpty ||
          serverFullSync is! bool ||
          (fullSync && !serverFullSync)) {
        throw const FormatException(
          'Respons sinkronisasi penugasan tidak lengkap.',
        );
      }
      final merged = <int, Map<String, dynamic>>{};
      if (!serverFullSync && cached != null) {
        for (final item in cached) {
          final id = _parseId(item['id']);
          if (id == null) {
            throw const FormatException('ID cache penugasan tidak valid.');
          }
          merged[id] = item;
        }
      }
      for (final value in rawRemovedIds) {
        final id = _parseId(value);
        if (id == null) {
          throw const FormatException('ID penugasan yang dihapus tidak valid.');
        }
        merged.remove(id);
      }
      for (final value in rawItems) {
        if (value is! Map) {
          throw const FormatException('Record penugasan tidak valid.');
        }
        final item = Map<String, dynamic>.from(value);
        final id = _parseId(item['id']);
        if (id == null) {
          throw const FormatException('ID penugasan tidak valid.');
        }
        merged[id] = item;
      }
      final data = merged.values.toList();
      await localStorage.saveAssignments(
        data,
        cacheScope: cacheScope,
        cursor: nextCursor,
        fullSyncAt: serverFullSync
            ? DateTime.now().millisecondsSinceEpoch
            : fullSyncAt as int?,
      );
      lastSyncError = null;
      return data.map(AssignmentItem.fromJson).toList();
    } catch (error) {
      lastSyncError = error.toString();
      if (cached != null) {
        return cached.map(AssignmentItem.fromJson).toList();
      }
      rethrow;
    }
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
      final studentId = _parseId(payload['student_id']);
      if (schoolId == null || userId == null || studentId == null) {
        throw const FormatException();
      }
      return 'school_${schoolId}_user_${userId}_student_$studentId';
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
