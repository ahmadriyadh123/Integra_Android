import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../data/model/elearning/elearning_model.dart';
import '../../../data/repositories/elearning/elearning_repository.dart';
import '../../../data/services/elearning/offline_material_service.dart';

enum OfflineMaterialToggleResult { saved, removed, unavailable }

/// Owns cached material state and mutations for one course screen session.
class OfflineMaterialController extends ChangeNotifier {
  final ElearningRepository _repository;
  final String _token;
  late final OfflineMaterialService _service = OfflineMaterialService(
    _repository,
  );

  final Set<int> _offlineSlideIds = {};
  final Set<int> _downloadingSlideIds = {};
  int? _loadedCourseId;
  bool _isDisposed = false;

  OfflineMaterialController({
    required ElearningRepository repository,
    required String token,
  }) : _repository = repository,
       _token = token;

  Set<int> get offlineSlideIds => Set.unmodifiable(_offlineSlideIds);
  Set<int> get downloadingSlideIds => Set.unmodifiable(_downloadingSlideIds);

  Future<void> loadForCourse(CourseDetail? detail) async {
    if (_isDisposed || detail == null || _loadedCourseId == detail.id) return;
    _loadedCourseId = detail.id;
    _offlineSlideIds.clear();
    _downloadingSlideIds.clear();

    for (final slide in detail.slides) {
      if (slide.isQuiz) continue;
      final file = await getSavedMaterial(slide.id);
      if (_isDisposed) return;
      if (file != null) _offlineSlideIds.add(slide.id);
    }
    _notifyListeners();
  }

  Future<File?> getSavedMaterial(int slideId) =>
      _repository.getOfflineMaterial(_token, slideId);

  Future<File?> downloadAndSave(SlideItem slide) async {
    if (_isDisposed ||
        slide.isQuiz ||
        slide.downloadUrl == null ||
        slide.downloadUrl!.isEmpty ||
        _downloadingSlideIds.contains(slide.id)) {
      return null;
    }

    _downloadingSlideIds.add(slide.id);
    _notifyListeners();
    try {
      final file = await _service.downloadAndSave(slide, _token);
      if (!_isDisposed && file != null) _offlineSlideIds.add(slide.id);
      return file;
    } finally {
      _downloadingSlideIds.remove(slide.id);
      _notifyListeners();
    }
  }

  Future<OfflineMaterialToggleResult> toggle(SlideItem slide) async {
    if (_isDisposed ||
        slide.isQuiz ||
        _downloadingSlideIds.contains(slide.id)) {
      return OfflineMaterialToggleResult.unavailable;
    }

    final savedFile = await getSavedMaterial(slide.id);
    if (savedFile == null) {
      final downloaded = await downloadAndSave(slide);
      return downloaded == null
          ? OfflineMaterialToggleResult.unavailable
          : OfflineMaterialToggleResult.saved;
    }

    await _repository.localStorage.removeOfflineMaterial(
      slide.id,
      cacheScope: _repository.cacheScopeForToken(_token),
    );
    if (_isDisposed) return OfflineMaterialToggleResult.unavailable;
    _offlineSlideIds.remove(slide.id);
    _notifyListeners();
    return OfflineMaterialToggleResult.removed;
  }

  void _notifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
