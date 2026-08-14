import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/viewmodel/auth_viewmodel.dart';
import '../auth/view/login_view.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/profile_section_card.dart';
import 'widgets/profile_logout_button.dart';

class ProfilTab extends StatelessWidget {
  const ProfilTab({super.key});

  @override
  Widget build(BuildContext context) {
    const Color backgroundSlate = Color(0xFFF8FAFC);

    final user = context.watch<AuthViewModel>().user;

    final String name = user?.name.isNotEmpty == true
        ? user!.name
        : user?.username ?? '-';

    final String className = user?.className.isNotEmpty == true
        ? user!.className
        : '-';

    final String email = user?.email.isNotEmpty == true
        ? user!.email
        : '-';

    final String username = user?.username ?? '-';

    return Scaffold(
      backgroundColor: backgroundSlate,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            ProfileHeaderCard(
              name: name,
              className: className,
              rombel: '',
              imageUrl: '',
              onEditTap: () {},
            ),
            const SizedBox(height: 24),

            // Seksi 1: Data Akademik
            const ProfileSectionLabel(title: 'DATA AKADEMIK'),
            const SizedBox(height: 8),
            ProfileSectionCard(
              children: [
                ProfileRowItem(
                  icon: Icons.perm_identity_rounded,
                  label: 'Nama Lengkap',
                  value: name,
                ),
                ProfileRowItem(
                  icon: Icons.alternate_email_rounded,
                  label: 'Username',
                  value: username,
                ),
                ProfileRowItem(
                  icon: Icons.class_outlined,
                  label: 'Kelas',
                  value: className,
                ),
                ProfileRowItem(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: email,
                  showDivider: false,
                ),
              ],
            ),

            const SizedBox(height: 32),
            ProfileLogoutButton(
              onLogoutTap: () {
                context.read<AuthViewModel>().logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginView()),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
