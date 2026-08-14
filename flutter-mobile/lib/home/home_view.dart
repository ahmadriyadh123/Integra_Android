import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/viewmodel/auth_viewmodel.dart';
import 'widgets/home_header.dart';
import 'widgets/home_quick_menu.dart';
import 'widgets/home_announcement_card.dart';

class HomeView extends StatelessWidget {
  final String authToken;
  final void Function(Widget page)? onMenuTap;
  final void Function(int index)? onTabSwitch;

  const HomeView({
    super.key,
    required this.authToken,
    this.onMenuTap,
    this.onTabSwitch,
  });

  static const Color backgroundSlate = Color(0xFFF8FAFC);
  static const Color textSlate = Color(0xFF475569);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;

    final String studentName = user?.name.isNotEmpty == true
        ? user!.name
        : user?.username ?? 'Siswa';

    final String className = user?.className.isNotEmpty == true
        ? user!.className
        : '';

    return Scaffold(
      backgroundColor: backgroundSlate,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHeader(
                studentName: studentName,
                className: className,
                onNotificationTap: () {},
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MENU UTAMA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: textSlate,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: HomeQuickMenu(
                        authToken: authToken,
                        onMenuTap: onMenuTap,
                        onTabSwitch: onTabSwitch,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'INFORMASI & PENGUMUMAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: textSlate,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    HomeAnnouncementCard(
                      title: 'Persiapan Ujian Tengah Semester (UTS) Genap',
                      date: '28 Jul 2026',
                      description: 'Diberitahukan kepada seluruh siswa agar mempersiapkan perangkat CBT dan memeriksa kembali tagihan administrasi.',
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}