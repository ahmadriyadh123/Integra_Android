import 'dart:io';
import '../services/scorm_service.dart';

class ScormRepository {
  final ScormService scormService;

  ScormRepository({ScormService? scormService})
      : scormService = scormService ?? ScormService();

  /// Authenticate Odoo web session
  Future<void> authenticateOdooWebSession({
    required Uri targetUri,
    required String odooDb,
    required String odooUsername,
    required String odooPassword,
  }) async {
    return scormService.authenticateOdooWebSession(
      targetUri: targetUri,
      odooDb: odooDb,
      odooUsername: odooUsername,
      odooPassword: odooPassword,
    );
  }

  /// Download SCORM zip file from URL
  Future<File> downloadZipFile(Uri uri, String token) async {
    return scormService.downloadZipFile(uri, token);
  }

  /// Extract SCORM zip file to directory
  Future<Directory> extractZip(File zipFile) async {
    return scormService.extractZip(zipFile);
  }

  /// Find index HTML file in extracted SCORM directory
  String findIndexPath(Directory extractDir) {
    return scormService.findIndexPath(extractDir);
  }

  /// Start local HTTP server to serve SCORM content
  Future<String> startLocalServer(Directory extractDir, String indexPath) async {
    return scormService.startLocalServer(extractDir, indexPath);
  }

  /// Get authentication headers for API requests
  Map<String, String> getAuthHeaders(String token) {
    return scormService.getAuthHeaders(token);
  }

  /// Close/cleanup server and extracted directory resources
  Future<void> cleanup() async {
    final server = scormService.server;
    if (server != null) {
      try {
        await server.close(force: true);
      } catch (_) {}
    }

    final extractDir = scormService.extractDir;
    if (extractDir != null && await extractDir.exists()) {
      try {
        await extractDir.delete(recursive: true);
      } catch (_) {}
    }
  }
}
