import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/user_friendly_error.dart';
import 'package:provider/provider.dart';
import '../auth/repositories/auth_repository.dart';
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
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmation.isEmpty) {
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
      final status = await authViewModel.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (!mounted) return;
      if (status == PasswordChangeStatus.queued) {
        setState(() {
          _isLoading = false;
          _currentController.clear();
          _newController.clear();
          _confirmationController.clear();
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _currentController.clear();
        _newController.clear();
        _confirmationController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil diperbarui.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = userFriendlyError(
          e,
          fallback: 'Password belum dapat diperbarui. Silakan coba lagi.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

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
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            if (authViewModel.passwordChangeSyncMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: authViewModel.passwordChangePending
                      ? const Color(0xFFFFF7ED)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (authViewModel.isSyncingPasswordChange)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        authViewModel.passwordChangePending
                            ? Icons.cloud_upload_outlined
                            : Icons.cloud_done_outlined,
                        size: 18,
                        color: authViewModel.passwordChangePending
                            ? const Color(0xFFB45309)
                            : const Color(0xFF047857),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authViewModel.passwordChangeSyncMessage!,
                            style: TextStyle(
                              color: authViewModel.passwordChangePending
                                  ? const Color(0xFF9A3412)
                                  : const Color(0xFF065F46),
                              fontSize: 12,
                            ),
                          ),
                          if (authViewModel.passwordChangePending &&
                              !authViewModel.isSyncingPasswordChange)
                            TextButton(
                              onPressed:
                                  authViewModel.cancelPendingPasswordChange,
                              child: const Text('Batalkan permintaan tertunda'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            _passwordField(
              controller: _currentController,
              label: 'Password lama',
              obscureText: _obscureCurrent,
              onToggle: () =>
                  setState(() => _obscureCurrent = !_obscureCurrent),
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
              onToggle: () =>
                  setState(() => _obscureConfirmation = !_obscureConfirmation),
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
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }
}
