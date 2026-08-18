import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../widgets/shared_header.dart';

class ScormPlayerView extends StatefulWidget {
  final String scormUrl;
  final String authToken;

  const ScormPlayerView({super.key, required this.scormUrl, this.authToken = ''});

  @override
  State<ScormPlayerView> createState() => _ScormPlayerViewState();
}

class _ScormPlayerViewState extends State<ScormPlayerView> {
  bool _isLoading = true;
  String? _error;
  String? _startUrl; // URL to index.html served by local HTTP server
  Directory? _extractDir;
  WebViewController? _webController;
  HttpServer? _server;

  @override
  void initState() {
    super.initState();
    _prepareScorm();
  }

  @override
  void dispose() {
    // Shutdown local server and clean up extracted files when leaving the screen
    try {
      _server?.close(force: true);
    } catch (_) {}
    try {
      if (_extractDir != null && _extractDir!.existsSync()) {
        _extractDir!.deleteSync(recursive: true);
      }
    } catch (_) {}
    super.dispose();
  }

  Future<void> _prepareScorm() async {
    try {
      final uri = Uri.parse(widget.scormUrl);
      // Download
      final headers = widget.authToken.isNotEmpty ? {'Authorization': 'Bearer \\'} : <String, String>{};
      final response = await http.get(uri, headers: headers);
      if (response.statusCode != 200) {
        throw Exception('Gagal mengunduh SCORM (status ${response.statusCode})');
      }

      final tempDir = await getTemporaryDirectory();
      final zipFile = File('${tempDir.path}/scorm_${DateTime.now().millisecondsSinceEpoch}.zip');
      await zipFile.writeAsBytes(response.bodyBytes);

      // Extract
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

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

      // Find index.html or default to first .html
      String? indexPath;
      final allFiles = extractDir.listSync(recursive: true);
      for (final f in allFiles) {
        if (f is File) {
          final lower = f.path.toLowerCase();
          if (lower.endsWith('/index.html') || lower.endsWith('index.html')) {
            indexPath = f.path;
            break;
          }
        }
      }

      if (indexPath == null) {
        // find any html file
        for (final f in allFiles) {
          if (f is File) {
            final lower = f.path.toLowerCase();
            if (lower.endsWith('.html')) {
              indexPath = f.path;
              break;
            }
          }
        }
      }

      if (indexPath == null) throw Exception('Tidak menemukan file HTML di dalam paket SCORM');

      // Start a local HTTP server to serve extracted files (fixes relative asset loading)
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.autoCompress = true;
      server.listen((HttpRequest request) async {
        try {
          final requestPath = Uri.decodeComponent(request.uri.path);
          print('[SCORM SERVER] request: ${request.method} ${request.uri}');
          String relPath = requestPath;

          // Hilangkan leading slash
          if (relPath.startsWith('/')) {
            relPath = relPath.substring(1);
          }

          // Jika kosong, fallback ke indexPath
          if (relPath.isEmpty) {
            if (indexPath != null) {
              relPath = indexPath
                  .substring(extractDir.path.length + 1)
                  .replaceAll('\\', '/');
            } else {
              // fallback default kalau indexPath null
              relPath = '';
            }
          }
          
          final fileToServe = File('${extractDir.path}${Platform.pathSeparator}$relPath');
          if (!await fileToServe.exists()) {
            final alt = File('${extractDir.path}${Platform.pathSeparator}$relPath/index.html');
            if (await alt.exists()) {
              final bytes = await alt.readAsBytes();
              request.response.headers.contentType = ContentType.html;
              request.response.add(bytes);
              await request.response.close();
              print('[SCORM SERVER] served alt index for $relPath');
              return;
            }
            request.response.statusCode = HttpStatus.notFound;
            await request.response.close();
            print('[SCORM SERVER] 404 $relPath');
            return;
          }

          final ext = fileToServe.path.contains('.') ? fileToServe.path.split('.').last.toLowerCase() : '';
          final contentType = _contentTypeForExt(ext);
          if (contentType != null) request.response.headers.contentType = contentType;
          final bytes = await fileToServe.readAsBytes();
          request.response.add(bytes);
          await request.response.close();
          print('[SCORM SERVER] 200 $relPath (served ${bytes.length} bytes)');
        } catch (e) {
          try {
            request.response.statusCode = HttpStatus.internalServerError;
            await request.response.close();
          } catch (_) {}
          print('[SCORM SERVER] error handling request: $e');
        }
      }, onError: (e) {
        print('[SCORM SERVER] listen error: $e');
      });

      final relativeIndex = ('/' + indexPath.substring(extractDir.path.length).replaceAll('\\', '/'));
      final startUrl = 'http://127.0.0.1:${server.port}$relativeIndex';

      setState(() {
        _extractDir = extractDir;
        _server = server;
        _startUrl = startUrl;
        // Initialize WebView controller for the local file with navigation delegate for logging
        _webController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(NavigationDelegate(
            onProgress: (progress) => print('[WEBVIEW] progress: $progress'),
            onPageStarted: (url) => print('[WEBVIEW] page started: $url'),
            onPageFinished: (url) => print('[WEBVIEW] page finished: $url'),
            onWebResourceError: (err) => print('[WEBVIEW] resource error: ${err.description}'),
          ))
          ..loadRequest(Uri.parse(_startUrl!));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
        return ContentType("application", "xml", charset: "utf-8");
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SharedHeader(
        title: 'SCORM PLAYER',
        centerTitle: true,
        showBackButton: true,
        onBack: () => Navigator.pop(context),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _startUrl == null
                  ? const Center(child: Text('Tidak ada konten untuk ditampilkan'))
                  : (_webController == null
                      ? const Center(child: Text('Preparing viewer...'))
                      : Column(
                          children: [
                            Container(
                              color: Colors.black12,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.link, size: 14),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Local URL: $_startUrl',
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(child: WebViewWidget(controller: _webController!)),
                          ],
                        )),
    );
  }
}




