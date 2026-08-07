import 'package:flutter/material.dart';
import '../models/elearning_model.dart';
import '../repositories/elearning_repository.dart';
import '../local/elearning_local_storage.dart';

class ElearningViewModel extends ChangeNotifier {
  final ElearningRepository repository;
  final ElearningLocalStorage localStorage;

  ElearningViewModel({
    required this.repository,
    required this.localStorage,
  });

  // ── Daftar kursus ─────────────────────────────────────────────────────────

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
      final cached = await localStorage.loadCourses();
      if (cached != null && cached.isNotEmpty) {
        _courses = cached.map(CourseItem.fromJson).toList();
        _isRefreshingCourses = true;
        notifyListeners();

        // Refresh di background tanpa loading indicator penuh
        try {
          final fresh = await repository.getCourses(token);
          _courses = fresh;
          await localStorage.saveCourses(
              fresh.map(_courseItemToMap).toList());
        } catch (_) {
          // Gagal refresh — tetap tampilkan cache, error tidak ditampilkan
        } finally {
          _isRefreshingCourses = false;
          notifyListeners();
        }
        return;
      }
    }

    // Tidak ada cache atau forceRefresh → loading penuh
    _isLoadingCourses = true;
    notifyListeners();

    try {
      final fresh = await repository.getCourses(token);
      _courses = fresh;
      await localStorage.saveCourses(fresh.map(_courseItemToMap).toList());
    } catch (e) {
      _coursesError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingCourses = false;
      notifyListeners();
    }
  }

  // ── Detail kursus ─────────────────────────────────────────────────────────

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
      final cached = await localStorage.loadCourseDetail(courseId);
      if (cached != null) {
        _courseDetail = CourseDetail.fromJson(cached);
        _isRefreshingDetail = true;
        notifyListeners();

        // Refresh di background
        try {
          final fresh = await repository.getCourseDetail(token, courseId);
          _courseDetail = fresh;
          await localStorage.saveCourseDetail(courseId, _courseDetailToMap(fresh));
        } catch (_) {
          // Gagal refresh — tetap tampilkan cache
        } finally {
          _isRefreshingDetail = false;
          notifyListeners();
        }
        return;
      }
    }

    // Tidak ada cache atau forceRefresh → loading penuh
    _isLoadingDetail = true;
    _courseDetail = null;
    notifyListeners();

    try {
      final fresh = await repository.getCourseDetail(token, courseId);
      _courseDetail = fresh;
      await localStorage.saveCourseDetail(courseId, _courseDetailToMap(fresh));
    } catch (e) {
      _detailError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  // ── Cache management ──────────────────────────────────────────────────────

  Future<void> clearAllCache(String token) async {
    await localStorage.clearAll();
    _courses = [];
    _courseDetail = null;
    _coursesError = null;
    _detailError = null;
    notifyListeners();
    await fetchCourses(token, forceRefresh: true);
  }

  Future<void> clearDetailCache(String token, int courseId) async {
    await localStorage.clearCourseDetail(courseId);
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

  // ── Serialisasi untuk cache ───────────────────────────────────────────────

  Map<String, dynamic> _courseItemToMap(CourseItem c) => {
        'id': c.id,
        'title': c.title,
        'teacher_name': c.teacherName,
        'total_slides': c.totalSlides,
        'description': c.description,
      };

  Map<String, dynamic> _courseDetailToMap(CourseDetail d) => {
        'id': d.id,
        'title': d.title,
        'teacher_name': d.teacherName,
        'description': d.description,
        'total_slides': d.totalSlides,
        'slides': d.slides
            .map((s) => {
                  'id': s.id,
                  'title': s.title,
                  'material_type': s.materialType,
                  'download_url': s.downloadUrl,
                  'sequence': s.sequence,
                })
            .toList(),
      };
}
