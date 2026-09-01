import 'package:flutter/material.dart';
import '../models/elearning_model.dart';
import '../repositories/elearning_repository.dart';

class ElearningViewModel extends ChangeNotifier {
  final ElearningRepository repository;

  ElearningViewModel({
    required this.repository,
  });


  bool _isLoadingCourses = false;
  bool get isLoadingCourses => _isLoadingCourses;

  /// true saat sedang refresh di background (cache sudah ditampilkan)
  bool _isRefreshingCourses = false;
  bool get isRefreshingCourses => _isRefreshingCourses;

  String? _coursesError;
  String? get coursesError => _coursesError;

  List<CourseItem> _courses = [];
  List<CourseItem> get courses => _courses;
  bool get hasCourses => _courses.isNotEmpty;

  /// Cache-first fetch:
  /// 1. Tampilkan cache seketika (jika ada & fresh)
  /// 2. Refresh dari API di background — update UI setelah selesai
  /// 3. Jika cache expired/kosong → loading penuh sampai API selesai
  Future<void> fetchCourses(String token, {bool forceRefresh = false}) async {
    _coursesError = null;

    if (!forceRefresh) {
      // Tampilkan cache terlebih dahulu, lalu perbarui tanpa mengosongkan UI.
      final cached = await repository.loadCachedCourses();
      if (cached != null && cached.isNotEmpty) {
        _courses = cached.map(CourseItem.fromJson).toList();
        _isRefreshingCourses = true;
        notifyListeners();

        // Refresh berjalan di background karena data cache sudah tersedia.
        try {
          final fresh = await repository.getCourses(token, forceRefresh: true);
          _courses = fresh;
          await repository.saveCachedCourses(fresh);
        } catch (_) {
          // Gagal refresh — tetap tampilkan cache, error tidak ditampilkan
        } finally {
          _isRefreshingCourses = false;
          notifyListeners();
        }
        return;
      }
    }

    // Tanpa cache, tampilkan loading penuh sampai data dari API tersedia.
    _isLoadingCourses = true;
    notifyListeners();

    try {
      final fresh = await repository.getCourses(token);
      _courses = fresh;
      await repository.saveCachedCourses(fresh);
    } catch (e) {
      _coursesError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingCourses = false;
      notifyListeners();
    }
  }


  bool _isLoadingDetail = false;
  bool get isLoadingDetail => _isLoadingDetail;

  bool _isRefreshingDetail = false;
  bool get isRefreshingDetail => _isRefreshingDetail;

  String? _detailError;
  String? get detailError => _detailError;

  CourseDetail? _courseDetail;
  CourseDetail? get courseDetail => _courseDetail;

  Future<void> fetchCourseDetail(String token, int courseId,
      {bool forceRefresh = false}) async {
    _detailError = null;

    if (!forceRefresh) {
      final cached = await repository.loadCachedCourseDetail(courseId);
      if (cached != null) {
        // Detail lama tetap ditampilkan selama versi terbaru sedang diambil.
        _courseDetail = CourseDetail.fromJson(cached);
        _isRefreshingDetail = true;
        notifyListeners();

        // Perbarui detail secara background agar tampilan tidak berkedip.
        try {
          final fresh = await repository.getCourseDetail(
            token,
            courseId,
            forceRefresh: true,
          );
          _courseDetail = fresh;
          await repository.saveCachedCourseDetail(courseId, fresh);
        } catch (_) {
          // Gagal refresh — tetap tampilkan cache
        } finally {
          _isRefreshingDetail = false;
          notifyListeners();
        }
        return;
      }
    }

    // Tanpa cache, detail harus menunggu hasil API sebelum ditampilkan.
    _isLoadingDetail = true;
    _courseDetail = null;
    notifyListeners();

    try {
      final fresh = await repository.getCourseDetail(token, courseId);
      _courseDetail = fresh;
      await repository.saveCachedCourseDetail(courseId, fresh);
    } catch (e) {
      _detailError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }


  Future<void> clearAllCache(String token) async {
    await repository.clearAllCache();
    _courses = [];
    _courseDetail = null;
    _coursesError = null;
    _detailError = null;
    notifyListeners();
    await fetchCourses(token, forceRefresh: true);
  }

  Future<void> clearDetailCache(String token, int courseId) async {
    await repository.clearCourseDetailCache(courseId);
    await fetchCourseDetail(token, courseId, forceRefresh: true);
  }

  void clearDetail() {
    _courseDetail = null;
    _detailError = null;
    _isLoadingDetail = false;
    _isRefreshingDetail = false;
  }

  void reset() {
    _courses = [];
    _coursesError = null;
    _isLoadingCourses = false;
    _isRefreshingCourses = false;
    clearDetail();
  }
}
