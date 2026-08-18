import 'dart:async';
import 'dart:convert';
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

  const ScormPlayerView({
    super.key,
    required this.scormUrl,
    this.authToken = '',
  });

  @override
  State<ScormPlayerView> createState() => _ScormPlayerViewState();
}

class _ScormPlayerViewState extends State<ScormPlayerView> {
  bool _isLoading = true;
  String? _statusMessage;
  String? _error;
  String? _startUrl;
  Directory? _extractDir;
  WebViewController? _webController;
  HttpServer? _server;
  bool _isDisposed = false;

  // In-memory store for basic SCORM key/value data
  final Map<String, String> _scormData = {};

  @override
  void initState() {
    super.initState();
    _prepareScorm();
  }

  @override
  void dispose() {
    _isDisposed = true;
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

  Map<String, String> _authHeaders() {
    final h = <String, String>{'User-Agent': 'FlutterApp/1.0'};
    if (widget.authToken.isNotEmpty) {
      h['Authorization'] = 'Bearer ${widget.authToken}';
    }
    return h;
  }

  Future<File> _downloadZipFile(Uri uri) async {
    final tempDir = await getTemporaryDirectory();
    final zipFile = File('${tempDir.path}/scorm_${DateTime.now().millisecondsSinceEpoch}.zip');

    final client = http.Client();
    try {
      final request = http.Request('GET', uri);
      request.headers.addAll(_authHeaders());

      final streamed = await client.send(request).timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw TimeoutException('Waktu koneksi unduh habis (timeout)'),
      );

      if (streamed.statusCode == 200) {
        final sink = zipFile.openWrite();
        await streamed.stream.pipe(sink);
        await sink.close();
        debugPrint('[SCORM] Download completed successfully: ${zipFile.path}');
        return zipFile;
      }

      throw Exception('Gagal mengunduh SCORM (HTTP ${streamed.statusCode})');
    } finally {
      client.close();
    }
  }

  Future<void> _prepareScorm() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _statusMessage = 'Mengunduh paket SCORM...';
    });

    File? zipFile;
    try {
      final uri = Uri.parse(widget.scormUrl);
      debugPrint('[SCORM] starting download from: $uri');

      zipFile = await _downloadZipFile(uri);

      if (_isDisposed) return;
      if (mounted) {
        setState(() => _statusMessage = 'Mengekstrak berkas SCORM...');
      }

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      debugPrint('[SCORM] zip decoded with ${archive.length} entries');

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

      debugPrint('[SCORM] extraction finished at: ${extractDir.path}');

      try {
        if (zipFile.existsSync()) zipFile.deleteSync();
      } catch (_) {}

      late String indexPath;
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

      debugPrint('[SCORM] chosen index.html: $indexPath');

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.autoCompress = true;
      server.listen((HttpRequest request) async {
        try {
          var requestPath = Uri.decodeComponent(request.uri.path);
          if (requestPath.startsWith('/')) requestPath = requestPath.substring(1);

          // default to index if path empty
          if (requestPath.isEmpty) {
            var r = indexPath.substring(extractDir.path.length).replaceAll('\\', '/');
            if (r.startsWith('/')) r = r.substring(1);
            requestPath = r;
          }

          final fileToServe = File('${extractDir.path}${Platform.pathSeparator}$requestPath');
          if (!await fileToServe.exists()) {
            final alt = File('${extractDir.path}${Platform.pathSeparator}$requestPath/index.html');
            if (await alt.exists()) {
              request.response.headers.contentType = ContentType.html;
              request.response.add(await alt.readAsBytes());
              await request.response.close();
              return;
            }
            request.response.statusCode = HttpStatus.notFound;
            await request.response.close();
            return;
          }

          final ext = fileToServe.path.contains('.') ? fileToServe.path.split('.').last.toLowerCase() : '';
          final contentType = _contentTypeForExt(ext);
          if (contentType != null) request.response.headers.contentType = contentType;
          request.response.add(await fileToServe.readAsBytes());
          await request.response.close();
        } catch (e) {
          try { request.response.statusCode = HttpStatus.internalServerError; await request.response.close(); } catch (_) {}
        }
      });

      // build startUrl safely
      final pathFromExtract = indexPath.substring(extractDir.path.length).replaceAll('\\', '/');
      final normalizedPath = pathFromExtract.startsWith('/') ? pathFromExtract.substring(1) : pathFromExtract;
      final startUrl = Uri(scheme: 'http', host: '127.0.0.1', port: server.port, path: normalizedPath).toString();
      debugPrint('[SCORM] startUrl resolved to: $startUrl');
      debugPrint('[SCORM] local server started on port ${server.port}');

      // Prepare WebView controller and bridge
      final controller = WebViewController();
      controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      controller.addJavaScriptChannel('ScormHost', onMessageReceived: (message) {
        try {
          final Map msg = jsonDecode(message.message) as Map;
          final String? type = msg['type'] as String?;
          final Map? payload = msg['payload'] as Map?;
          debugPrint('[SCORM-BRIDGE] received: type=$type payload=$payload');
          if (type == 'set' && payload != null) {
            final key = payload['key']?.toString() ?? '';
            final value = payload['value']?.toString() ?? '';
            _scormData[key] = value;
          } else if (type == 'get' && payload != null) {
            final key = payload['key']?.toString() ?? '';
            debugPrint('[SCORM-BRIDGE] get($key) -> ${_scormData[key] ?? ''}');
          } else if (type == 'initialize') {
            debugPrint('[SCORM-BRIDGE] initialize (${payload?['api'] ?? 'unknown'})');
          } else if (type == 'commit') {
            debugPrint('[SCORM-BRIDGE] commit');
            _onScormCommit();
          } else if (type == 'finish') {
            debugPrint('[SCORM-BRIDGE] finish');
            _onScormFinish();
          }
        } catch (e) {
          debugPrint('[SCORM-BRIDGE] invalid message: ${message.message}');
        }
      });

      controller.setNavigationDelegate(NavigationDelegate(
        onProgress: (progress) => debugPrint('[WEBVIEW] progress: $progress%'),
        onPageStarted: (url) async {
          debugPrint('[WEBVIEW] page started: $url');
          // inject shim so SCORM content can call window.API / window.API_1484_11
          const scormBridge = r"""
(function(){
  function send(type, payload){
    var msg = JSON.stringify({type:type, payload: payload||{}});
    if (window.ScormHost && window.ScormHost.postMessage) {
      window.ScormHost.postMessage(msg);
    } else if (window.flutter_inappwebview && window.flutter_inappwebview.postMessage) {
      window.flutter_inappwebview.postMessage(msg);
    } else if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.ScormHost) {
      try{ window.webkit.messageHandlers.ScormHost.postMessage(msg);}catch(e){}
    } else { console.log('[SCORM BRIDGE] host channel not found'); }
  }

  window.API = window.API || {
    LMSInitialize: function(){ send('initialize',{api:'1.2'}); return 'true'; },
    LMSFinish: function(){ send('finish',{api:'1.2'}); return 'true'; },
    LMSGetValue: function(k){ send('get',{key:k,api:'1.2'}); return ''; },
    LMSSetValue: function(k,v){ send('set',{key:k,value:v,api:'1.2'}); return 'true'; },
    LMSCommit: function(){ send('commit',{api:'1.2'}); return 'true'; },
  };

  window.API_1484_11 = window.API_1484_11 || {
    Initialize: function(){ send('initialize',{api:'2004'}); return 'true'; },
    Terminate: function(){ send('finish',{api:'2004'}); return 'true'; },
    GetValue: function(k){ send('get',{key:k,api:'2004'}); return ''; },
    SetValue: function(k,v){ send('set',{key:k,value:v,api:'2004'}); return 'true'; },
    Commit: function(){ send('commit',{api:'2004'}); return 'true'; },
  };
})();
""";
          try {
            await controller.runJavaScript(scormBridge);
            debugPrint('[SCORM-BRIDGE] shim injected');
          } catch (e) {
            debugPrint('[SCORM-BRIDGE] inject error: $e');
          }
        },
        onPageFinished: (url) => debugPrint('[WEBVIEW] page finished: $url'),
        onWebResourceError: (err) => debugPrint('[WEBVIEW] resource error: ${err.description}'),
      ));

      controller.loadRequest(Uri.parse(startUrl));

      if (!mounted || _isDisposed) {
        _extractDir = extractDir;
        _server = server;
        _startUrl = startUrl;
        _webController = controller;
        _isLoading = false;
        return;
      }

      setState(() {
        _extractDir = extractDir;
        _server = server;
        _startUrl = startUrl;
        _webController = controller;
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('[SCORM] prepare error: $e');
      debugPrint('[SCORM] prepare stack trace: $st');
      if (zipFile != null && zipFile.existsSync()) {
        try { zipFile.deleteSync(); } catch (_) {}
      }

      final msg = e.toString().replaceAll('Exception: ', '');
      if (!mounted || _isDisposed) {
        _error = msg;
        _isLoading = false;
        return;
      }
      setState(() { _error = msg; _isLoading = false; });
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
        return ContentType('application', 'xml', charset: 'utf-8');
      default:
        return null;
    }
  }

  void _onScormCommit() {
    debugPrint('[SCORM] commit event - saving ${_scormData.length} keys');
    // TODO: persist or send to backend
  }

  void _onScormFinish() {
    debugPrint('[SCORM] finish event - data keys: ${_scormData.keys.toList()}');
    if (!mounted || _isDisposed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SCORM: Modul selesai. Progress tersimpan secara lokal.')),
    );
    // TODO: send _scormData to backend using widget.authToken
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
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF059669)),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage ?? 'Memuat SCORM...',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 56, color: Color(0xFFEF4444)),
                        const SizedBox(height: 16),
                        const Text('Gagal Membuka SCORM', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _prepareScorm,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ],
                    ),
                  ),
                )
              : _startUrl == null
                  ? const Center(child: Text('Tidak ada konten untuk ditampilkan'))
                  : (_webController == null
                      ? const Center(child: Text('Preparing viewer...'))
                      : Column(
                          children: [
                            Container(
                              color: Colors.black12,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Row(children: [const Icon(Icons.link, size: 14), const SizedBox(width: 8), Expanded(child: Text('Local URL: $_startUrl', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis))]),
                            ),
                            Expanded(child: WebViewWidget(controller: _webController!)),
                          ],
                        )),
    );
  }
}
