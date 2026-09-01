import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/view/login_view.dart';
import '../auth/viewmodel/auth_viewmodel.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirmation = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final currentPassword = _currentController.text;
    final newPassword = _newController.text;
    final confirmation = _confirmationController.text;

    setState(() => _errorMessage = null);
    if (currentPassword.isEmpty || newPassword.isEmpty || confirmation.isEmpty) {
      setState(() => _errorMessage = 'Semua field password wajib diisi.');
      return;
    }
    if (newPassword.length < 6) {
      setState(() => _errorMessage = 'Password baru minimal 6 karakter.');
      return;
    }
    if (newPassword != confirmation) {
      setState(() => _errorMessage = 'Konfirmasi password tidak cocok.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authViewModel = context.read<AuthViewModel>();
      await authViewModel.repository.changePassword(
        token: authViewModel.token,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (!mounted) return;
      await authViewModel.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Ganti Password'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perbarui password akun Anda',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gunakan password minimal 6 karakter dan jangan bagikan kepada orang lain.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 24),
            _passwordField(
              controller: _currentController,
              label: 'Password lama',
              obscureText: _obscureCurrent,
              onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
            ),
            const SizedBox(height: 16),
            _passwordField(
              controller: _newController,
              label: 'Password baru',
              obscureText: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 16),
            _passwordField(
              controller: _confirmationController,
              label: 'Konfirmasi password baru',
              obscureText: _obscureConfirmation,
              onToggle: () => setState(() => _obscureConfirmation = !_obscureConfirmation),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_reset_rounded),
                label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Password'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF059669),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
        ),
        suffixIcon: IconButton(
          tooltip: obscureText ? 'Tampilkan password' : 'Sembunyikan password',
          onPressed: onToggle,
          icon: Icon(obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined),
        ),
      ),
    );
  }
}
