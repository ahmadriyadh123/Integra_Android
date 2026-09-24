import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/auth_viewmodel.dart';
import '../../dashboard/dashboard_view.dart';
import '../widgets/app_logo.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/error_banner.dart';
import '../widgets/primary_button.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key, this.initialBaseUrl = '', this.onServerSaved});

  final String initialBaseUrl;
  final Future<void> Function(String baseUrl)? onServerSaved;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _serverFieldKey = GlobalKey<FormFieldState<String>>();
  late final TextEditingController _serverController;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isSavingServer = false;

  @override
  void initState() {
    super.initState();
    _serverController = TextEditingController(text: widget.initialBaseUrl);
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
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

  Future<void> _saveServer() async {
    if (widget.onServerSaved == null) return;
    if (!_serverFieldKey.currentState!.validate()) return;

    setState(() => _isSavingServer = true);
    await widget.onServerSaved!(_normalizeBaseUrl(_serverController.text));
    if (mounted) setState(() => _isSavingServer = false);
  }

  Future<void> _onLoginPressed() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<AuthViewModel>();
    final success = await viewModel.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      final token = viewModel.token;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => DashboardView(authToken: token)),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppLogo(
                    title: 'INTEGRA MOBILE APP',
                    subtitle: 'Silakan masuk ke akun siswa Anda',
                    assetPath: 'assets/app_icon.png',
                  ),
                  const SizedBox(height: 32),
                  _buildFormCard(),
                  const SizedBox(height: 24),
                  const Text(
                    '© 2026 Integra Edusolusi. All rights reserved.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.onServerSaved != null) ...[
              TextFormField(
                key: _serverFieldKey,
                controller: _serverController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Alamat server API',
                  hintText: '192.168.1.7:8000',
                  prefixIcon: Icon(Icons.dns_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'API path /api/v1 ditambahkan otomatis',
                ),
                validator: (value) {
                  final input = value?.trim() ?? '';
                  if (input.isEmpty) return 'Alamat server wajib diisi';
                  final uri = Uri.tryParse(_normalizeBaseUrl(input));
                  if (uri == null || uri.host.isEmpty) {
                    return 'Format alamat server tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _isSavingServer ? null : _saveServer,
                  icon: _isSavingServer
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Simpan alamat server'),
                ),
              ),
              const SizedBox(height: 16),
            ],
            CustomTextField(
              label: 'Email',
              hint: 'Masukkan email',
              prefixIcon: Icons.person_outline_rounded,
              controller: _usernameController,
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Email tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Password',
              hint: 'Masukkan password',
              prefixIcon: Icons.lock_outline_rounded,
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _onLoginPressed(),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Password tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Consumer<AuthViewModel>(
              builder: (context, viewModel, _) {
                if (viewModel.errorMessage == null) {
                  return const SizedBox.shrink();
                }
                return ErrorBanner(
                  message: viewModel.errorMessage!,
                  onClose: () => viewModel.clearError(),
                );
              },
            ),
            Consumer<AuthViewModel>(
              builder: (context, viewModel, _) {
                return PrimaryButton(
                  text: 'Login',
                  isLoading: viewModel.isLoading,
                  onPressed: _onLoginPressed,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
