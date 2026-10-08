import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/auth_viewmodel.dart';
import '../services/auth_service.dart';
import '../models/school_model.dart';
import '../../dashboard/dashboard_view.dart';
import '../widgets/app_logo.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/error_banner.dart';
import '../widgets/primary_button.dart';
import '../../../services/tenant_api_config.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key, this.initialSchoolId = '', this.onSchoolIdSaved});

  final String initialSchoolId;
  final Future<void> Function(String schoolId)? onSchoolIdSaved;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _schoolMenuScrollController = ScrollController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late String? _selectedSchoolId;
  List<SchoolOption> _schools = const [];
  bool _isLoadingSchools = true;
  bool _isRefreshingSchools = false;
  String? _schoolLoadError;
  String? _schoolRefreshError;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _selectedSchoolId = widget.initialSchoolId.isEmpty
        ? null
        : widget.initialSchoolId;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadSchools(showCachedFirst: true),
    );
  }

  @override
  void dispose() {
    _schoolMenuScrollController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSchools({bool showCachedFirst = false}) async {
    final authService = context.read<AuthService>();
    if (showCachedFirst) {
      try {
        final cachedSchools = await authService.loadCachedSchools();
        if (!mounted) return;
        if (cachedSchools != null) {
          setState(() {
            _schools = cachedSchools;
            _isLoadingSchools = false;
          });
        }
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _schoolLoadError = error.toString().replaceFirst('Exception: ', '');
          _isLoadingSchools = false;
        });
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoadingSchools = _schools.isEmpty;
      _isRefreshingSchools = true;
      _schoolLoadError = null;
      _schoolRefreshError = null;
    });

    try {
      final schools = await authService.fetchSchools(forceRefresh: true);
      if (!mounted) return;
      setState(() {
        _schools = schools;
        _isLoadingSchools = false;
        _isRefreshingSchools = false;
        _schoolLoadError = schools.isEmpty
            ? 'Belum ada sekolah aktif yang tersedia.'
            : null;
        if (!schools.any((school) => school.id == _selectedSchoolId)) {
          _selectedSchoolId = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingSchools = false;
        _isRefreshingSchools = false;
        final message = error.toString().replaceFirst('Exception: ', '');
        if (_schools.isEmpty) {
          _schoolLoadError = message;
        } else {
          _schoolRefreshError = message;
        }
      });
    }
  }

  Future<void> _onLoginPressed() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final schoolId = _selectedSchoolId;
    if (schoolId == null) return;
    context.read<TenantApiConfig>().schoolId = schoolId;
    await widget.onSchoolIdSaved?.call(schoolId);
    if (!mounted) return;

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
            _buildSchoolDropdown(),
            const SizedBox(height: 20),
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

  Widget _buildSchoolDropdown() {
    final selectedSchoolId =
        _schools.any((school) => school.id == _selectedSchoolId)
        ? _selectedSchoolId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Nama sekolah',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _isRefreshingSchools ? null : () => _loadSchools(),
              icon: _isRefreshingSchools
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Perbarui'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_schoolRefreshError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Gagal memperbarui daftar. Menampilkan data tersimpan: '
              '$_schoolRefreshError',
              style: const TextStyle(color: Color(0xFFB45309), fontSize: 12),
            ),
          ),
        const SizedBox(height: 4),
        FormField<String>(
          key: ValueKey(selectedSchoolId),
          initialValue: selectedSchoolId,
          validator: (value) {
            if (_schoolLoadError != null && _schools.isEmpty) {
              return 'Daftar sekolah tidak tersedia';
            }
            if (value == null) return 'Silakan pilih sekolah';
            return null;
          },
          builder: (field) => LayoutBuilder(
            builder: (context, constraints) => MenuAnchor(
              alignmentOffset: const Offset(0, 4),
              style: MenuStyle(
                padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                minimumSize: WidgetStatePropertyAll(
                  Size(constraints.maxWidth, 0),
                ),
                maximumSize: WidgetStatePropertyAll(
                  Size(constraints.maxWidth, 260),
                ),
                backgroundColor: const WidgetStatePropertyAll(Colors.white),
                elevation: const WidgetStatePropertyAll(8),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              menuChildren: [
                SizedBox(
                  width: constraints.maxWidth,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: SingleChildScrollView(
                      controller: _schoolMenuScrollController,
                      primary: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _schools
                            .map((school) {
                              final isSelected = school.id == field.value;
                              return SizedBox(
                                width: double.infinity,
                                child: MenuItemButton(
                                  style: MenuItemButton.styleFrom(
                                    backgroundColor: isSelected
                                        ? const Color(0xFFECFDF5)
                                        : Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: () {
                                    field.didChange(school.id);
                                    setState(
                                      () => _selectedSchoolId = school.id,
                                    );
                                  },
                                  child: Text(
                                    school.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFF047857)
                                          : const Color(0xFF0F172A),
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            })
                            .toList(growable: false),
                      ),
                    ),
                  ),
                ),
              ],
              builder: (context, menuController, child) {
                final isEnabled =
                    !_isLoadingSchools &&
                    (_schoolLoadError == null || _schools.isNotEmpty);
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: isEnabled
                      ? () {
                          FocusScope.of(context).unfocus();
                          if (menuController.isOpen) {
                            menuController.close();
                          } else {
                            menuController.open();
                          }
                        }
                      : null,
                  child: InputDecorator(
                    isEmpty: field.value == null,
                    decoration: InputDecoration(
                      errorText: field.errorText,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      enabled: isEnabled,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF059669),
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDC2626)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _schools
                                    .where((school) => school.id == field.value)
                                    .firstOrNull
                                    ?.name ??
                                (_isLoadingSchools
                                    ? 'Memuat daftar sekolah...'
                                    : 'Pilih sekolah'),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: field.value == null
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF0F172A),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (_isLoadingSchools)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(
                            menuController.isOpen
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: const Color(0xFF64748B),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (_schoolLoadError != null && _schools.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _schoolLoadError!,
                    style: const TextStyle(color: Color(0xFFDC2626)),
                  ),
                ),
                TextButton(
                  onPressed: _loadSchools,
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
