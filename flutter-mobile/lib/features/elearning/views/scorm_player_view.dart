import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../repositories/scorm_repository.dart';
import '../services/scorm_service.dart';
import '../viewmodel/scorm_viewmodel.dart';
import '../../widgets/shared_header.dart';
import 'package:flutter_application_1/services/tenant_api_config.dart';

class ScormPlayerView extends StatefulWidget {
  final String scormUrl;
  final String authToken;
  final String odooUsername;
  final String odooPassword;
  final String odooDb;
  final Future<void> Function(String completionStatus)? onCompleted;

  const ScormPlayerView({
    super.key,
    required this.scormUrl,
    this.authToken = '',
    this.odooUsername = '',
    this.odooPassword = '',
    this.onCompleted,
    this.odooDb = const String.fromEnvironment(
      'ODOO_DB',
      defaultValue: 'kp-sekolah.asetkoptii.com',
    ),
  });

  @override
  State<ScormPlayerView> createState() => _ScormPlayerViewState();
}

class _ScormPlayerViewState extends State<ScormPlayerView> {
  late final ScormViewModel _viewModel;
  WebViewController? _webController;
  bool _completionReported = false;

  @override
  void initState() {
    super.initState();
    final repository = ScormRepository(
      scormService: ScormService(
        tenantApiConfig: context.read<TenantApiConfig>(),
      ),
    );
    _viewModel = ScormViewModel(repository: repository);
    _viewModel.addListener(_onViewModelUpdate);
    _viewModel.prepareScorm(
      widget.scormUrl,
      widget.authToken,
      odooUsername: widget.odooUsername,
      odooPassword: widget.odooPassword,
      odooDb: widget.odooDb,
    );
  }

  void _onViewModelUpdate() {
    if (!_viewModel.isLoading &&
        _viewModel.error == null &&
        _viewModel.startUrl != null) {
      _initWebViewController(_viewModel.startUrl!);
    }
    if (mounted) setState(() {});
  }

  void _initWebViewController(String url) {
    if (_webController != null) return;

    final controller = WebViewController();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);

    controller.addJavaScriptChannel(
      'ScormHost',
      onMessageReceived: (message) {
        try {
          final Map msg = jsonDecode(message.message) as Map;
          final type = msg['type'] as String? ?? '';
          _viewModel.handleBridgeMessage(type, msg['payload'] as Map?);
          if (type == 'commit' || type == 'finish') {
            _reportCompletion();
          }
        } catch (_) {}
      },
    );

    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) async {
          const scormBridge = r"""
(function(){
  function send(type, payload){
    var msg = JSON.stringify({type:type, payload: payload||{}});
    if (window.ScormHost && window.ScormHost.postMessage) {
      window.ScormHost.postMessage(msg);
    }
  }
  window.API = window.API || {
    LMSInitialize: function(){ send('initialize',{api:'1.2'}); return 'true'; },
    LMSFinish: function(){ send('finish',{api:'1.2'}); return 'true'; },
    LMSGetValue: function(k){ send('get',{key:k,api:'1.2'}); return ''; },
    LMSSetValue: function(k,v){ send('set',{key:k,value:v,api:'1.2'}); return 'true'; },
    LMSCommit: function(){ send('commit',{api:'1.2'}); return 'true'; },
  };
})();
""";
          try {
            await controller.runJavaScript(scormBridge);
          } catch (_) {}
        },
      ),
    );

    controller.loadRequest(
      Uri.parse(url),
      headers: _viewModel.getAuthHeaders(widget.authToken),
    );

    _webController = controller;
  }

  Future<void> _reportCompletion() async {
    final completionStatus = _viewModel.completionStatus?.toLowerCase();
    if (_completionReported ||
        !_viewModel.isCompleted ||
        completionStatus == null ||
        widget.onCompleted == null) {
      return;
    }

    _completionReported = true;
    try {
      await widget.onCompleted!(completionStatus);
    } catch (error) {
      _completionReported = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status selesai SCORM belum tersimpan: '
            '${error.toString().replaceAll('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelUpdate);
    _viewModel.dispose();
    super.dispose();
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
      body: _viewModel.isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF059669)),
                  const SizedBox(height: 16),
                  Text(
                    _viewModel.statusMessage ?? 'Memuat SCORM...',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            )
          : _viewModel.error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 56,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 16),
                  Text(_viewModel.error!, textAlign: TextAlign.center),
                ],
              ),
            )
          : _webController == null
          ? const Center(child: Text('Memuat viewer...'))
          : WebViewWidget(controller: _webController!),
    );
  }
}
