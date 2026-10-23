/// Mixin yang mengimplementasikan pola Stale-While-Revalidate untuk ChangeNotifier.
///
/// Alur:
///   1. Ada data di cache? → tampilkan segera ke UI, set isRefreshing = true
///   2. Fetch dari API di latar belakang → update UI saat selesai
///   3. Tidak ada cache? → isLoading = true sampai API selesai (loading penuh)
///
/// Dengan pola ini swipe-to-refresh tidak pernah mengosongkan layar —
/// user melihat data lama sambil menunggu data baru.
///
/// Cara pakai:
///   class MyViewModel extends ChangeNotifier with StaleWhileRevalidateMixin {
///     `Future<void>` fetchData(String token, {bool forceRefresh = false}) =>
///         swr(
///           hasStale: _items.isNotEmpty,
///           forceRefresh: forceRefresh,
///           load: () => _loadFromCache(token),    // kembalikan data dari Hive
///           fetch: () => _fetchFromApi(token),    // panggil API
///           onData: (data) => _items = data,
///         );
///   }

library;

import 'package:flutter/foundation.dart';

mixin StaleWhileRevalidateMixin on ChangeNotifier {
  bool _isLoading = false;
  bool _isRefreshing = false;

  /// True saat tidak ada data sama sekali dan sedang menunggu API (layar kosong).
  bool get isLoading => _isLoading;

  /// True saat data lama sudah ditampilkan dan refresh berjalan di latar belakang.
  bool get isRefreshing => _isRefreshing;

  /// Jalankan fetch dengan pola stale-while-revalidate.
  ///
  /// - [hasStale]      : apakah ada data lama yang sudah tersedia di memori
  /// - [forceRefresh]  : jika true, paksa fetch dari API meski cache fresh
  /// - [load]          : fungsi untuk mengambil data dari cache/Hive,
  ///                     kembalikan null jika tidak ada
  /// - [fetch]         : fungsi untuk mengambil data terbaru dari API
  /// - [onData]        : callback saat data berhasil didapat (dari cache atau API)
  /// - [onError]       : callback saat error (opsional)
  Future<void> swr<T>({
    required bool hasStale,
    required bool forceRefresh,
    required Future<T?> Function() load,
    required Future<T> Function() fetch,
    required void Function(T data) onData,
    void Function(Object error)? onError,
  }) async {
    // Fase 1: muat dari cache jika ada dan tidak dipaksa refresh
    if (!forceRefresh) {
      T? cached;
      try {
        cached = await load();
      } catch (_) {
        cached = null;
      }

      if (cached != null) {
        onData(cached);
        _isRefreshing = true;
        _isLoading = false;
        notifyListeners();

        // Fase 2: refresh dari API di latar belakang
        try {
          final fresh = await fetch();
          onData(fresh);
        } catch (e) {
          // Gagal refresh — data lama tetap tampil, tidak hapus UI
          onError?.call(e);
        } finally {
          _isRefreshing = false;
          notifyListeners();
        }
        return;
      }
    }

    // Fase 3: tidak ada cache atau forceRefresh — loading penuh
    _isLoading = true;
    _isRefreshing = false;
    notifyListeners();

    try {
      final fresh = await fetch();
      onData(fresh);
    } catch (e) {
      onError?.call(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
