import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/user_friendly_error.dart';
import '../repositories/scorm_repository.dart';

class ScormViewModel extends ChangeNotifier {
  final ScormRepository repository;

  ScormViewModel({required this.repository});

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _statusMessage;
  String? get statusMessage => _statusMessage;

  String? _error;
  String? get error =>
      _error == null ? null : userFriendlyError(_error!);

  String? _startUrl;
  String? get startUrl => _startUrl;

  final Map<String, String> _scormData = {};
  Map<String, String> get scormData => _scormData;
  String? get completionStatus =>
      _scormData['cmi.core.lesson_status'] ??
      _scormData['cmi.completion_status'];
  bool get isCompleted =>
      const {'completed', 'passed'}.contains(completionStatus?.toLowerCase());

  Future<void> prepareScorm(
      String scormUrl, 
      String authToken, {
      String odooUsername = '',
      String odooPassword = '',
      String odooDb = '',
      String? offlinePackagePath,
    }) async {
      _isLoading = true;
      _error = null;
      _statusMessage = 'Mengunduh paket SCORM...';
      notifyListeners();

      File? zipFile;
      try {
        final offlinePackage = offlinePackagePath == null
            ? null
            : File(offlinePackagePath);
        final useOfflinePackage =
            offlinePackage != null && await offlinePackage.exists();
        final uri = Uri.parse(scormUrl);
        final lowerUrl = uri.path.toLowerCase();

      // Jika URL bukan berkas .zip
        final isMiddlewareDownload = lowerUrl.contains('/api/v1/elearning/content/') &&
          lowerUrl.endsWith('/download');

        if (!useOfflinePackage &&
            !lowerUrl.endsWith('.zip') &&
            !isMiddlewareDownload) {
        // Lakukan autentikasi sesi Odoo jika kredensial tersedia
        if (odooUsername.isNotEmpty && odooPassword.isNotEmpty) {
          _statusMessage = 'Menghubungkan sesi Odoo...';
          notifyListeners();

          await repository.authenticateOdooWebSession(
            targetUri: uri,
            odooDb: odooDb,
            odooUsername: odooUsername,
            odooPassword: odooPassword,
          );
        }

        _startUrl = scormUrl;
        _isLoading = false;
        _statusMessage = null;
        notifyListeners();
        return;
      }

      zipFile = useOfflinePackage
          ? offlinePackage
          : await repository.downloadZipFile(uri, authToken);
      _statusMessage = 'Mengekstrak berkas SCORM...';
      notifyListeners();

      final extractDir = await repository.extractZip(
        zipFile,
        deleteSource: !useOfflinePackage,
      );
      final indexPath = repository.findIndexPath(extractDir);
      final resolvedStartUrl = await repository.startLocalServer(extractDir, indexPath);

      _startUrl = resolvedStartUrl;
      _isLoading = false;
      _statusMessage = null;
      notifyListeners();
    } catch (e) {
      if (zipFile != null &&
          zipFile.existsSync() &&
          zipFile.path != offlinePackagePath) {
        try { zipFile.deleteSync(); } catch (_) {}
      }
      _error = userFriendlyError(
        e,
        fallback: 'Materi belum dapat dibuka. Silakan coba lagi.',
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  void handleBridgeMessage(String type, Map? payload) {
    if (type == 'set' && payload != null) {
      final key = payload['key']?.toString() ?? '';
      final value = payload['value']?.toString() ?? '';
      _scormData[key] = value;
    } else if (type == 'commit') {
      debugPrint('[SCORM-VM] commit event: ${_scormData.length} keys');
    } else if (type == 'finish') {
      debugPrint('[SCORM-VM] finish event');
    }
  }

  /// Get authentication headers for API requests
  Map<String, String> getAuthHeaders(String token) {
    return repository.getAuthHeaders(token);
  }

  @override
  void dispose() {
    repository.cleanup();
    super.dispose();
  }
}