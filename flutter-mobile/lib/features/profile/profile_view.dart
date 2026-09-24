import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../auth/viewmodel/auth_viewmodel.dart';
import '../auth/view/login_view.dart';
import 'change_password_view.dart';
import 'viewmodel/profile_viewmodel.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/profile_section_card.dart';
import 'widgets/profile_logout_button.dart';

class ProfilTab extends StatefulWidget {
  const ProfilTab({super.key});

  @override
  State<ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<ProfilTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authViewModel = context.read<AuthViewModel>();
      final profileViewModel = context.read<ProfileViewModel>();
      profileViewModel.loadProfile(
        authViewModel.token,
        fallbackPartnerId: authViewModel.user?.partnerId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundSlate = Color(0xFFF8FAFC);

    final authViewModel = context.watch<AuthViewModel>();
    final profileViewModel = context.watch<ProfileViewModel>();
    final profile = profileViewModel.profile;
    final user = authViewModel.user;

    final String name = profile?.name.isNotEmpty == true
        ? profile!.name
        : user?.name.isNotEmpty == true
        ? user!.name
        : (user?.username.isNotEmpty == true ? user!.username : '-');

    final String nis = _firstValue(profile?.nis, user?.nis);
    final String nisn = _firstValue(profile?.nisn, user?.nisn);
    final String className = _firstValue(profile?.className, user?.className);
    final String rombel = _firstValue(profile?.rombel, user?.rombel);
    final String tempatTanggalLahir = _firstValue(
      profile?.tempatTanggalLahir,
      user?.tempatTanggalLahir,
    );
    final String usia = _firstValue(profile?.usia, user?.usia);

    final String imageUrl = _resolveImageUrl(
      profileViewModel.baseUrl,
      profile?.photoUrl,
      user?.partnerId,
    );

    return Scaffold(
      backgroundColor: backgroundSlate,
      body: RefreshIndicator(
        color: const Color(0xFF059669),
        onRefresh: () async {
          final authViewModel = context.read<AuthViewModel>();
          final token = authViewModel.token;
          final partnerId = authViewModel.user?.partnerId;
          final profileViewModel = context.read<ProfileViewModel>();
          await profileViewModel.loadProfile(token, fallbackPartnerId: partnerId);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              ProfileHeaderCard(
                name: name,
                className: className,
                rombel: rombel,
                imageUrl: imageUrl,
                imageBytes: profileViewModel.profileImage,
                authToken: authViewModel.token,
              ),
              const SizedBox(height: 24),

              const ProfileSectionLabel(title: 'IDENTITAS SISWA'),
              const SizedBox(height: 8),
              ProfileSectionCard(
                children: [
                  ProfileRowItem(
                    icon: Icons.perm_identity_rounded,
                    label: 'Nama Lengkap',
                    value: name,
                  ),
                  ProfileRowItem(
                    icon: Icons.badge_outlined,
                    label: 'NIS',
                    value: nis,
                  ),
                  ProfileRowItem(
                    icon: Icons.card_membership_outlined,
                    label: 'NISN',
                    value: nisn,
                  ),
                  ProfileRowItem(
                    icon: Icons.class_outlined,
                    label: 'Kelas',
                    value: className,
                  ),
                  ProfileRowItem(
                    icon: Icons.meeting_room_outlined,
                    label: 'Rombel',
                    value: rombel,
                  ),
                  ProfileRowItem(
                    icon: Icons.cake_outlined,
                    label: 'Tempat, Tanggal Lahir',
                    value: tempatTanggalLahir,
                  ),
                  ProfileRowItem(
                    icon: Icons.hourglass_bottom_rounded,
                    label: 'Usia',
                    value: usia,
                    showDivider: false,
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const ProfileSectionLabel(title: 'KEAMANAN AKUN'),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordView(),
                    ),
                  ),
                  icon: const Icon(Icons.lock_reset_rounded),
                  label: const Text('Ganti Password'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF059669),
                    side: const BorderSide(color: Color(0xFFA7F3D0)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              ProfileLogoutButton(
                onLogoutTap: _confirmLogout,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    await context.read<AuthViewModel>().logout();
    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  String _firstValue(String? profileValue, String? sessionValue) {
    if (profileValue?.isNotEmpty == true) return profileValue!;
    if (sessionValue?.isNotEmpty == true) return sessionValue!;
    return '-';
  }

  String _buildPartnerImageUrl(String baseUrl, int? partnerId) {
    if (partnerId == null || partnerId <= 0) {
      return '';
    }
    return '$baseUrl/profile/image/$partnerId';
  }

  String _resolveImageUrl(String baseUrl, String? photoUrl, int? partnerId) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('http')) return photoUrl;
      final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      final cleanPath = photoUrl.startsWith('/') ? photoUrl : '/$photoUrl';
      if (cleanBase.endsWith('/api/v1') && cleanPath.startsWith('/api/v1')) {
        return '${cleanBase.replaceAll(RegExp(r'/api/v1$'), '')}$cleanPath';
      }
      return '$cleanBase$cleanPath';
    }
    return _buildPartnerImageUrl(baseUrl, partnerId);
  }
}
