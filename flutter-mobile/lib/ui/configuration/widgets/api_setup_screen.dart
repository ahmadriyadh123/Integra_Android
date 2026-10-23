import 'package:flutter/material.dart';

class ApiSetupView extends StatefulWidget {
  const ApiSetupView({
    super.key,
    this.initialValue = '',
    required this.onSaved,
  });

  final String initialValue;
  final Future<void> Function(String baseUrl) onSaved;

  @override
  State<ApiSetupView> createState() => _ApiSetupViewState();
}

class _ApiSetupViewState extends State<ApiSetupView> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _normalizeBaseUrl(String value) {
    var baseUrl = value.trim();
    if (!baseUrl.startsWith('http://') && !baseUrl.startsWith('https://')) {
      baseUrl = 'http://$baseUrl';
    }
    baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    if (!baseUrl.endsWith('/api/v1')) {
      baseUrl = '$baseUrl/api/v1';
    }
    return baseUrl;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    await widget.onSaved(_normalizeBaseUrl(_controller.text));
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.dns_outlined,
                          size: 52,
                          color: Colors.teal,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Pengaturan Server',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Masukkan IP komputer yang menjalankan middleware API.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _controller,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'IP atau alamat server',
                            hintText: '192.168.1.7:8000',
                            prefixIcon: Icon(Icons.link),
                            border: OutlineInputBorder(),
                            helperText: 'Bisa berupa IP:port atau URL lengkap',
                          ),
                          onFieldSubmitted: (_) => _save(),
                          validator: (value) {
                            final input = value?.trim() ?? '';
                            if (input.isEmpty) {
                              return 'Alamat server wajib diisi';
                            }
                            final normalized = _normalizeBaseUrl(input);
                            final uri = Uri.tryParse(normalized);
                            if (uri == null || uri.host.isEmpty) {
                              return 'Format alamat server tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: const Text('Simpan dan lanjutkan'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
