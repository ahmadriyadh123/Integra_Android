import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ScormService {
  HttpServer? _server;
  Directory? _extractDir;

  HttpServer? get server => _server;
  Directory? get extractDir => _extractDir;

  Map<String, String> getAuthHeaders(String token) {
    final h = <String, String>{'User-Agent': 'FlutterApp/1.0'};
    if (token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Future<void> authenticateOdooWebSession({
    required Uri targetUri,
    required String odooDb,
    required String odooUsername,
    required String odooPassword,
  }) async {
    final sessionUri = Uri(
      scheme: targetUri.scheme,
      host: targetUri.host,
      port: targetUri.port,
      path: '/web/session/authenticate',
    );

    try {
      final response = await http.post(
        sessionUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'params': {
            'db': odooDb,
            'login': odooUsername,
            'password': odooPassword,
          },
        }),
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final result = body['result'];
      final sessionId = result is Map<String, dynamic>
          ? result['session_id'] as String?
          : null;

      if (response.statusCode == 200 && sessionId != null && sessionId.isNotEmpty) {
        final cookieManager = WebViewCookieManager();
        await cookieManager.setCookie(WebViewCookie(
          name: 'session_id',
          value: sessionId,
          domain: targetUri.host,
          path: '/',
        ));
      }
    } catch (e) {
      debugPrint('[SCORM-SERVICE] Web session login error: $e');
    }
  }

  Future<File> downloadZipFile(Uri uri, String token) async {
    final tempDir = await getTemporaryDirectory();
    final zipFile = File('${tempDir.path}/scorm_${DateTime.now().millisecondsSinceEpoch}.zip');
    final client = http.Client();

    try {
      final request = http.Request('GET', uri);
      request.headers.addAll(getAuthHeaders(token));

      final streamedResponse = await client.send(request).timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw TimeoutException('Waktu koneksi unduh habis (timeout)'),
      );

      if (streamedResponse.statusCode == 200) {
        final sink = zipFile.openWrite();
        await streamedResponse.stream.pipe(sink);
        await sink.close();
        return zipFile;
      }
      throw Exception('Gagal mengunduh SCORM (HTTP ${streamedResponse.statusCode})');
    } finally {
      client.close();
    }
  }

  Future<Directory> extractZip(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final tempDir = await getTemporaryDirectory();
    final extractDir = Directory('${tempDir.path}/scorm_${DateTime.now().millisecondsSinceEpoch}');
    if (!await extractDir.exists()) await extractDir.create(recursive: true);

    for (final file in archive) {
      final filename = file.name;
      final outPath = '${extractDir.path}/$filename';
      if (file.isFile) {
        final outFile = File(outPath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }

    try {
      if (zipFile.existsSync()) zipFile.deleteSync();
    } catch (_) {}

    _extractDir = extractDir;
    return extractDir;
  }

  String findIndexPath(Directory extractDir) {
    final allFiles = extractDir.listSync(recursive: true);
    String? indexPath;

    for (final f in allFiles) {
      if (f is File) {
        final lower = f.path.toLowerCase();
        if (lower.endsWith('index.html') ||
            lower.endsWith('index.htm') ||
            lower.endsWith('story.html') ||
            lower.endsWith('story.htm')) {
          indexPath = f.path;
          break;
        }
      }
    }

    if (indexPath == null) {
      for (final f in allFiles) {
        if (f is File) {
          final lower = f.path.toLowerCase();
          if (lower.endsWith('.html') || lower.endsWith('.htm') || lower.endsWith('.xhtml')) {
            indexPath = f.path;
            break;
          }
        }
      }
    }

    if (indexPath == null) throw Exception('Tidak menemukan file HTML di dalam paket SCORM');
    return indexPath;
  }

  Future<String> startLocalServer(Directory extractDir, String indexPath) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.autoCompress = true;

    server.listen((HttpRequest request) async {
      try {
        var requestPath = Uri.decodeComponent(request.uri.path);
        if (requestPath.startsWith('/')) requestPath = requestPath.substring(1);

        final fileToServe = File('${extractDir.path}${Platform.pathSeparator}$requestPath');
        if (await fileToServe.exists()) {
          final ext = fileToServe.path.contains('.') ? fileToServe.path.split('.').last.toLowerCase() : '';
          final contentType = _contentTypeForExt(ext);
          if (contentType != null) request.response.headers.contentType = contentType;
          request.response.add(await fileToServe.readAsBytes());
          await request.response.close();
          return;
        }

        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      } catch (e) {
        try {
          request.response.statusCode = HttpStatus.internalServerError;
          await request.response.close();
        } catch (_) {}
      }
    });

    _server = server;
    final pathFromExtract = indexPath.substring(extractDir.path.length).replaceAll('\\', '/');
    final normalizedPath = pathFromExtract.startsWith('/') ? pathFromExtract.substring(1) : pathFromExtract;
    return Uri(scheme: 'http', host: '127.0.0.1', port: server.port, path: normalizedPath).toString();
  }

  ContentType? _contentTypeForExt(String ext) {
    switch (ext) {
      case 'html':
      case 'htm':
        return ContentType.html;
      case 'css':
        return ContentType('text', 'css', charset: 'utf-8');
      case 'js':
        return ContentType('application', 'javascript', charset: 'utf-8');
      case 'json':
        return ContentType.json;
      case 'png':
        return ContentType('image', 'png');
      case 'jpg':
      case 'jpeg':
        return ContentType('image', 'jpeg');
      case 'gif':
        return ContentType('image', 'gif');
      case 'svg':
        return ContentType('image', 'svg+xml');
      case 'woff':
        return ContentType('font', 'woff');
      case 'woff2':
        return ContentType('font', 'woff2');
      case 'ttf':
        return ContentType('font', 'ttf');
      case 'mp4':
        return ContentType('video', 'mp4');
      case 'mp3':
        return ContentType('audio', 'mpeg');
      case 'xml':
        return ContentType('application', 'xml', charset: 'utf-8');
      default:
        return null;
    }
  }

  void cleanup() {
    try {
      _server?.close(force: true);
    } catch (_) {}
    try {
      if (_extractDir != null && _extractDir!.existsSync()) {
        _extractDir!.deleteSync(recursive: true);
      }
    } catch (_) {}
  }
}