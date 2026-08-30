import 'dart:io';
import 'package:flutter/material.dart';
import '../services/scorm_service.dart';

class ScormViewModel extends ChangeNotifier {
  final ScormService service;

  ScormViewModel({required this.service});

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _statusMessage;
  String? get statusMessage => _statusMessage;

  String? _error;
  String? get error => _error;

  String? _startUrl;
  String? get startUrl => _startUrl;

  final Map<String, String> _scormData = {};
  Map<String, String> get scormData => _scormData;

  Future<void> prepareScorm(
      String scormUrl, 
      String authToken, {
      String odooUsername = '',
      String odooPassword = '',
      String odooDb = '',
    }) async {
      _isLoading = true;
      _error = null;
      _statusMessage = 'Mengunduh paket SCORM...';
      notifyListeners();

      File? zipFile;
      try {
        final uri = Uri.parse(scormUrl);
        final lowerUrl = uri.path.toLowerCase();

      // Jika URL bukan berkas .zip
        final isMiddlewareDownload = lowerUrl.contains('/api/v1/elearning/content/') &&
          lowerUrl.endsWith('/download');

        if (!lowerUrl.endsWith('.zip') && !isMiddlewareDownload) {
        // Lakukan autentikasi sesi Odoo jika kredensial tersedia
        if (odooUsername.isNotEmpty && odooPassword.isNotEmpty) {
          _statusMessage = 'Menghubungkan sesi Odoo...';
          notifyListeners();

          await service.authenticateOdooWebSession(
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

      zipFile = await service.downloadZipFile(uri, authToken);
      _statusMessage = 'Mengekstrak berkas SCORM...';
      notifyListeners();

      final extractDir = await service.extractZip(zipFile);
      final indexPath = service.findIndexPath(extractDir);
      final resolvedStartUrl = await service.startLocalServer(extractDir, indexPath);

      _startUrl = resolvedStartUrl;
      _isLoading = false;
      _statusMessage = null;
      notifyListeners();
    } catch (e) {
      if (zipFile != null && zipFile.existsSync()) {
        try { zipFile.deleteSync(); } catch (_) {}
      }
      _error = e.toString().replaceAll('Exception: ', '');
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

  @override
  void dispose() {
    service.cleanup();
    super.dispose();
  }
}