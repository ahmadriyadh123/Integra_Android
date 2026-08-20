import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/viewmodel/auth_viewmodel.dart';
import 'widgets/home_header.dart';
import 'widgets/home_quick_menu.dart';

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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x05000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFECFDF5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.school_outlined,
                              color: Color(0xFF059669),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PORTAL SISWA',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: textSlate,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Selamat datang di Portal Siswa, sistem informasi terintegrasi yang mendukung kegiatan belajar dan administrasi sekolah secara digital, praktis, dan efisien.',
                                  style: TextStyle(
                                    color: textSlate,
                                    fontSize: 13,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    HomeQuickMenu(
                      authToken: authToken,
                      onMenuTap: onMenuTap,
                      onTabSwitch: onTabSwitch,
                    ),
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
