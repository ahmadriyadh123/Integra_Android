import 'dart:io';

import '../../model/elearning/elearning_model.dart';
import '../../repositories/elearning/elearning_repository.dart';
import './material_url_resolver.dart';

/// Handles downloading and persisting course materials for offline use.
class OfflineMaterialService {
  final ElearningRepository repository;

  const OfflineMaterialService(this.repository);

  Future<File?> downloadAndSave(SlideItem slide, String token) async {
    if (slide.isQuiz || slide.downloadUrl == null || slide.downloadUrl!.isEmpty) {
      return null;
    }

    var contentUrl = slide.downloadUrl!;
    if (slide.isScorm) {
      contentUrl = await repository.getSlideContent(token, slide.id);
    }

    final uri = resolveElearningMaterialUri(
      contentUrl,
      repository.apiService.baseUrl,
    );
    final response = await repository.apiService.downloadMaterial(token, uri);
    final contentType = response.headers['content-type']
        ?.split(';')
        .first
        .toLowerCase();
    if (contentType == 'text/html' ||
        contentType == 'application/json' ||
        contentType == 'text/json') {
      throw const FormatException(
        'Tautan materi tidak menghasilkan berkas yang dapat disimpan.',
      );
    }

    final extension = slide.isScorm
        ? 'zip'
        : _materialExtension(uri, response.headers, slide.materialType);
    final safeTitle = slide.title
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    await repository.saveOfflineMaterial(
      token,
      slide.id,
      fileName: '${slide.id}_$safeTitle.$extension',
      content: response.stream,
    );
    return repository.getOfflineMaterial(token, slide.id);
  }

  String _materialExtension(
    Uri uri,
    Map<String, String> headers,
    String materialType,
  ) {
    final contentDisposition = headers['content-disposition'];
    if (contentDisposition != null) {
      final filenameMatch = RegExp(
        r"filename\*?=(?:UTF-8'')?([^;]+)",
        caseSensitive: false,
      ).firstMatch(contentDisposition);
      final name = filenameMatch?.group(1)?.replaceAll('"', '').trim();
      final filenameExtension = name != null && name.contains('.')
          ? name.split('.').last
          : '';
      if (RegExp(r'^[A-Za-z0-9]{1,8}$').hasMatch(filenameExtension)) {
        return filenameExtension.toLowerCase();
      }
    }

    final path = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    final pathExtension = path.contains('.') ? path.split('.').last : '';
    if (RegExp(r'^[A-Za-z0-9]{1,8}$').hasMatch(pathExtension)) {
      return pathExtension.toLowerCase();
    }

    final contentType = headers['content-type']?.split(';').first.toLowerCase();
    return switch (contentType) {
      'application/pdf' => 'pdf',
      'video/mp4' => 'mp4',
      'video/webm' => 'webm',
      'video/quicktime' => 'mov',
      'application/zip' => 'zip',
      'application/msword' => 'doc',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document' =>
        'docx',
      'application/vnd.ms-powerpoint' => 'ppt',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation' =>
        'pptx',
      'application/vnd.ms-excel' => 'xls',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' =>
        'xlsx',
      _ => materialType == 'video' ? 'mp4' : 'pdf',
    };
  }
}
