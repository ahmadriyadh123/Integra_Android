import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/utils/user_friendly_error.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/view_models/auth_viewmodel.dart';

import '../../../data/model/elearning/elearning_model.dart';
import '../view_models/elearning_viewmodel.dart';
import './detail/course_header_banner.dart';
import './detail/teacher_info_card.dart';
import './detail/course_material_timeline.dart';
import './detail/course_progress_card.dart';
import '../../core/ui/shared_header.dart';
import '../../core/ui/app_refresh_indicator.dart';
import './scorm_player_screen.dart';
import './course_discussion_screen.dart';
import '../../../data/services/elearning/material_url_resolver.dart';
import '../view_models/offline_material_controller.dart';

const Color _green = Color(0xFF059669);
const Color _bgSlate = Color(0xFFF8FAFC);
const Color _textDark = Color(0xFF1E293B);

class DetailCourseView extends StatefulWidget {
  final int courseId;
  final String title;
  final String teacher;
  final String authToken;
  final IconData? iconData;
  final Color? iconBgColor;
  final Color? iconColor;

  const DetailCourseView({
    super.key,
    required this.courseId,
    required this.title,
    required this.teacher,
    required this.authToken,
    this.iconData,
    this.iconBgColor,
    this.iconColor,
  });

  @override
  State<DetailCourseView> createState() => _DetailCourseViewState();
}

class _DetailCourseViewState extends State<DetailCourseView> {
  late ElearningViewModel _vm;
  late OfflineMaterialController _offlineMaterials;
  bool _offlineControllerReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Simpan referensi ViewModel agar aman dipakai di dispose
    _vm = context.read<ElearningViewModel>();
    if (!_offlineControllerReady) {
      _offlineMaterials = OfflineMaterialController(
        repository: _vm.repository,
        token: widget.authToken,
      )..addListener(_onOfflineMaterialsChanged);
      _offlineControllerReady = true;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCourseDetail();
    });
  }

  Future<void> _loadCourseDetail({bool forceRefresh = false}) async {
    await _vm.fetchCourseDetail(
      widget.authToken,
      widget.courseId,
      forceRefresh: forceRefresh,
    );
    await _loadOfflineSlideStates();
  }

  Future<void> _loadOfflineSlideStates() =>
      _offlineMaterials.loadForCourse(_vm.courseDetail);

  void _onOfflineMaterialsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    // Bersihkan detail saat keluar agar fetch ulang saat masuk kursus lain
    try {
      _vm.clearDetail();
    } catch (_) {}
    if (_offlineControllerReady) {
      _offlineMaterials
        ..removeListener(_onOfflineMaterialsChanged)
        ..dispose();
    }
    super.dispose();
  }

  Future<void> _refreshCourseDetail() async {
    await _loadCourseDetail(forceRefresh: true);
    if (!mounted || _vm.detailError == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_vm.detailError!)));
  }

  Future<void> _openUrl(
    String? url, {
    bool isScorm = false,
    bool markCompletedOnOpen = true,
    int? slideId,
  }) async {
    File? offlineFile;
    if (slideId != null) {
      offlineFile = await _offlineMaterials.getSavedMaterial(slideId);
      if (!mounted) return;

      // "Membuka = mengunduh": jika materi belum tersimpan offline dan bisa
      // diunduh, unduh & simpan dulu, lalu buka berkas lokalnya. Bila gagal,
      // alur di bawah akan tetap menjatuhkan ke buka online (URL).
      if (offlineFile == null &&
          !_offlineMaterials.downloadingSlideIds.contains(slideId)) {
        final slide = _findSlide(slideId);
        if (slide != null &&
            !slide.isQuiz &&
            slide.downloadUrl != null &&
            slide.downloadUrl!.isNotEmpty) {
          offlineFile = await _downloadAndSaveMaterial(slide, silent: true);
          if (!mounted) return;
        }
      }
    }

    if ((url == null || url.isEmpty) && offlineFile == null) {
      _showSnack('Materi ini tidak tersedia secara langsung.');
      return;
    }

    if (offlineFile != null && !isScorm) {
      final result = await OpenFilex.open(offlineFile.path);
      if (result.type != ResultType.done) {
        _showSnack('Tidak dapat membuka berkas offline: ${result.message}');
        return;
      }
      if (markCompletedOnOpen && slideId != null) {
        await _recordOpenedMaterial(slideId);
      }
      return;
    }

    String fullUrl = url ?? '';
    String? offlinePackagePath = isScorm ? offlineFile?.path : null;

    if (isScorm && slideId != null && offlinePackagePath == null) {
      try {
        fullUrl = await _vm.repository.getSlideContent(
          widget.authToken,
          slideId,
        );
      } catch (e) {
        if (!mounted) return;
        _showSnack(
          userFriendlyError(
            e,
            fallback: 'Materi belum dapat dibuka. Silakan coba lagi.',
          ),
        );
        return;
      }
      if (!mounted) return;
    }

    if (fullUrl.isNotEmpty) {
      fullUrl = resolveElearningMaterialUri(
        fullUrl,
        _vm.repository.apiService.baseUrl,
      ).toString();
    }

    // Bersihkan semua duplikasi teks /api/v1/api/v1/ atau /elearning/elearning/ yang berulang akibat penggabungan sebelumnya
    while (fullUrl.contains('/api/v1/api/v1/')) {
      fullUrl = fullUrl.replaceAll('/api/v1/api/v1/', '/api/v1/');
    }
    while (fullUrl.contains('/elearning/elearning/')) {
      fullUrl = fullUrl.replaceAll('/elearning/elearning/', '/elearning/');
    }

    debugPrint('[OPEN_URL] Final clean URL: $fullUrl');

    final lowerUrl = fullUrl.toLowerCase();
    final isZip =
        lowerUrl.endsWith('.zip') || lowerUrl.contains('.zip') || isScorm;

    if (isScorm || isZip) {
      final authViewModel = context.read<AuthViewModel>();
      final username = await authViewModel.loadUsername();
      final password = await authViewModel.loadPassword();
      if (!mounted) return;
      final scormSlideId = slideId;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScormPlayerView(
            scormUrl: fullUrl,
            authToken: widget.authToken,
            odooUsername: username,
            odooPassword: password,
            offlinePackagePath: offlinePackagePath,
            onCompleted: scormSlideId == null
                ? null
                : (completionStatus) async {
                    await _vm.markSlideCompleted(
                      widget.authToken,
                      widget.courseId,
                      scormSlideId,
                      source: 'scorm',
                      completionStatus: completionStatus,
                    );
                    await _vm.fetchCourseDetail(
                      widget.authToken,
                      widget.courseId,
                      forceRefresh: true,
                    );
                    await _vm.fetchCourses(
                      widget.authToken,
                      forceRefresh: true,
                    );
                  },
          ),
        ),
      );
      return;
    }

    final uri = Uri.parse(fullUrl);
    if (await canLaunchUrl(uri)) {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched && !isScorm && markCompletedOnOpen && slideId != null) {
        await _recordOpenedMaterial(slideId);
      }
    } else {
      _showSnack('Tidak dapat membuka materi.');
    }
  }

  /// Mencari slide berdasarkan id pada course detail yang sedang aktif.
  SlideItem? _findSlide(int slideId) {
    final slides = _vm.courseDetail?.slides ?? const <SlideItem>[];
    for (final slide in slides) {
      if (slide.id == slideId) return slide;
    }
    return null;
  }

  /// Mengunduh & menyimpan materi ke penyimpanan offline.
  ///
  /// Dipakai oleh:
  /// - tombol "Simpan offline" (`_toggleOfflineMaterial`) -> `silent: false`
  /// - alur buka materi (`_openUrl`) -> `silent: true` sehingga membuka =
  ///   mengunduh tanpa snackbar tambahan (spinner pada slide jadi indikator).
  ///
  /// Mengembalikan [File] hasil simpan bila sukses, atau `null` bila gagal /
  /// materi tidak dapat diunduh / sedang mengunduh.
  Future<File?> _downloadAndSaveMaterial(
    SlideItem slide, {
    bool silent = false,
  }) async {
    if (slide.downloadUrl == null || slide.downloadUrl!.isEmpty) {
      if (!silent) {
        _showSnack('Berkas materi ini tidak tersedia untuk diunduh.');
      }
      return null;
    }
    try {
      final file = await _offlineMaterials.downloadAndSave(slide);
      if (!silent && file != null) {
        _showSnack('Materi berhasil disimpan untuk dibuka offline.');
      }
      return file;
    } catch (error) {
      if (!silent && mounted) {
        _showSnack(
          'Gagal menyimpan materi: ${userFriendlyError(error, fallback: 'Materi belum dapat disimpan. Silakan coba lagi.')}',
        );
      }
      return null;
    }
  }

  Future<void> _toggleOfflineMaterial(SlideItem slide) async {
    try {
      final result = await _offlineMaterials.toggle(slide);
      if (!mounted) return;
      switch (result) {
        case OfflineMaterialToggleResult.saved:
          _showSnack('Materi berhasil disimpan untuk dibuka offline.');
        case OfflineMaterialToggleResult.removed:
          _showSnack('Materi dihapus dari penyimpanan offline.');
        case OfflineMaterialToggleResult.unavailable:
          _showSnack('Berkas materi ini tidak tersedia untuk diunduh.');
      }
    } catch (error) {
      if (!mounted) return;
      _showSnack(
        'Gagal memperbarui penyimpanan offline: ${userFriendlyError(error, fallback: 'Materi belum dapat disimpan. Silakan coba lagi.')}',
      );
    }
  }

  Future<void> _recordOpenedMaterial(int slideId) async {
    try {
      await _vm.markSlideCompleted(
        widget.authToken,
        widget.courseId,
        slideId,
        source: 'opened',
      );
      await _vm.fetchCourseDetail(
        widget.authToken,
        widget.courseId,
        forceRefresh: true,
      );
      await _vm.fetchCourses(widget.authToken, forceRefresh: true);
    } catch (error) {
      if (!mounted) return;
      _showSnack(
        'Materi dibuka, tetapi progres belum tersimpan: ${userFriendlyError(error, fallback: 'Progres belajar belum dapat disimpan. Silakan coba lagi.')}',
      );
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFA7F3D0), size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 12))),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgSlate,
      body: AppRefreshIndicator(
        onRefresh: _refreshCourseDetail,
        child: Consumer<ElearningViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoadingDetail) {
              return _buildLoading();
            }
            if (vm.detailError != null && vm.courseDetail == null) {
              return _buildError(vm);
            }
            if (vm.courseDetail == null) {
              return _buildLoading();
            }
            return _buildContent(vm.courseDetail!);
          },
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: _bgSlate,
      appBar: SharedHeader(
        title: widget.title,
        backgroundColor: const Color(0xFF064E3B),
        foregroundColor: Colors.white,
        elevation: 0,
        showBackButton: true,
        onBack: () => Navigator.pop(context),
      ),
      body: const Center(child: CircularProgressIndicator(color: _green)),
    );
  }

  Widget _buildError(ElearningViewModel vm) {
    return Scaffold(
      backgroundColor: _bgSlate,
      appBar: SharedHeader(
        title: widget.title,
        backgroundColor: const Color(0xFF064E3B),
        foregroundColor: Colors.white,
        elevation: 0,
        showBackButton: true,
        onBack: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: Color(0xFFCBD5E1),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gagal Memuat Detail',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                vm.detailError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(CourseDetail detail) {
    final slides = detail.slides;
    final firstPlayableSlide = slides.cast<SlideItem?>().firstWhere(
      (slide) => slide?.downloadUrl?.isNotEmpty == true,
      orElse: () => null,
    );
    final firstVideoSlide = slides.cast<SlideItem?>().firstWhere(
      (slide) =>
          slide != null &&
          slide.isVideo &&
          slide.downloadUrl?.isNotEmpty == true,
      orElse: () => null,
    );

    return Consumer<ElearningViewModel>(
      builder: (context, vm, _) => Stack(
        children: [
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CourseHeaderBanner(
                  title: detail.title,
                  subtitle: detail.description.isNotEmpty
                      ? detail.description
                      : null,
                  durasiMenit: detail.totalSlides,
                  onBackTap: () => Navigator.pop(context),
                  showPlayButton: firstVideoSlide != null,
                  onPlayTap: firstVideoSlide == null
                      ? null
                      : () => _openUrl(
                          firstVideoSlide.downloadUrl,
                          isScorm: false,
                          markCompletedOnOpen: true,
                          slideId: firstVideoSlide.id,
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info guru
                      TeacherInfoCard(
                        teacherName: detail.teacherName,
                        onChatTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseDiscussionView(
                              courseId: detail.id,
                              courseTitle: detail.title,
                              authToken: widget.authToken,
                              repository: vm.repository,
                            ),
                          ),
                        ),
                      ),

                      // Deskripsi (jika ada)
                      if (detail.description.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Text(
                            detail.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      CourseProgressCard(detail: detail),

                      const SizedBox(height: 24),

                      CourseMaterialTimeline(
                        slides: slides,
                        offlineSlideIds: _offlineMaterials.offlineSlideIds,
                        downloadingSlideIds:
                            _offlineMaterials.downloadingSlideIds,
                        isRefreshing: vm.isRefreshingDetail,
                        onOpenSlide: (slide) => _openUrl(
                          slide.downloadUrl,
                          isScorm: slide.isScorm,
                          markCompletedOnOpen: slide.isVideo || slide.isPdf,
                          slideId: slide.id,
                        ),
                        onToggleOffline: _toggleOfflineMaterial,
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom CTA
          if (firstPlayableSlide != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomCTA(firstPlayableSlide),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomCTA(SlideItem? firstSlide) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _openUrl(
          firstSlide?.downloadUrl,
          isScorm: firstSlide?.isScorm ?? false,
          slideId: firstSlide?.id,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Mulai Belajar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
