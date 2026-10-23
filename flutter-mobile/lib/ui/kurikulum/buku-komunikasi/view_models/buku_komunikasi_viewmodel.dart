import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/services/core/stale_while_revalidate.dart';
import 'package:flutter_application_1/utils/user_friendly_error.dart';

import '../../../../data/model/kurikulum/buku-komunikasi/buku_komunikasi_model.dart';
import '../../../../data/repositories/kurikulum/buku-komunikasi/buku_komunikasi_repository.dart';

bool _isSessionError(String message) {
  final normalized = message.toLowerCase();
  return normalized.contains('sesi') ||
      normalized.contains('tidak valid') ||
      normalized.contains('berakhir') ||
      normalized.contains('login kembali') ||
      normalized.contains('unauthorized') ||
      normalized.contains('401');
}

class BukuKomunikasiViewModel extends ChangeNotifier
    with StaleWhileRevalidateMixin {
  final BukuKomunikasiRepository repository;

  BukuKomunikasiViewModel({required this.repository});

  // isLoading dan isRefreshing disediakan oleh StaleWhileRevalidateMixin

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  String? _errorMessage;
  String? get errorMessage =>
      _errorMessage == null ? null : userFriendlyError(_errorMessage!);

  bool get isSessionExpired =>
      _errorMessage != null && _isSessionError(_errorMessage!);

  BukuKomunikasiDetail? _detail;
  BukuKomunikasiDetail? get detail => _detail;

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;
  bool get hasPending => _pendingCount > 0;

  // ── Connectivity listener ────────────────────────────────────────────────────

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  String? _cachedToken;

  void startConnectivityListener(String token) {
    _cachedToken = token;
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (results) {
        final isOnline = results.any((r) => r != ConnectivityResult.none);
        if (isOnline && hasPending && !_isSyncing) {
          syncPendingNotes(_cachedToken ?? token);
        }
      },
    );
  }

  void stopConnectivityListener() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  @override
  void dispose() {
    stopConnectivityListener();
    super.dispose();
  }

  // ── Fetch ────────────────────────────────────────────────────────────────────

  Future<void> fetchBukuKomunikasi(String token,
      {bool forceRefresh = false}) async {
    await swr<BukuKomunikasiDetail?>(
      hasStale: _detail != null,
      forceRefresh: forceRefresh,
      load: () => repository.loadCachedBukuKomunikasi(token),
      fetch: () => repository.getBukuKomunikasi(token, forceRefresh: true),
      onData: (data) {
        _detail = data;
        _errorMessage = null;
      },
      onError: (e) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      },
    );
    // Perbarui pending count setelah fetch
    _pendingCount = await repository.pendingNoteCount(token);
    notifyListeners();
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<BukuKomunikasiSubmitStatus> submitDailyNote({
    required String token,
    required int lineId,
    required String day,
    required String noteText,
    String? month,
    int? week,
  }) async {
    // Tidak set isLoading agar data lama tetap tampil saat submit
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
        await fetchBukuKomunikasi(token, forceRefresh: false);
      } else if (status == BukuKomunikasiSubmitStatus.queued) {
        _pendingCount = await repository.pendingNoteCount(token);
        notifyListeners();
      }
      return status;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return BukuKomunikasiSubmitStatus.failed;
    }
  }

  // ── Sync pending ─────────────────────────────────────────────────────────────

  Future<int> syncPendingNotes(String token) async {
    if (_isSyncing) return 0;
    _isSyncing = true;
    notifyListeners();
    try {
      final synced = await repository.syncPendingNotes(token);
      if (synced > 0) {
        await fetchBukuKomunikasi(token, forceRefresh: false);
      }
      _pendingCount = await repository.pendingNoteCount(token);
      return synced;
    } catch (_) {
      return 0;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
