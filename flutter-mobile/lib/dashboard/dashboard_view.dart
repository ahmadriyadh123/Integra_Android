import 'package:flutter/material.dart';

// --- Import View Tab Utama ---
import '../home/home_view.dart';
import '../kehadiran/view/attendance_view.dart';
import '../profile/profile_view.dart';

class DashboardView extends StatefulWidget {
  final String authToken;

  const DashboardView({
    super.key,
    required this.authToken,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // List tab navigasi utama
    final List<Widget> tabs = [
      // Tab 0: Home / Beranda
      HomeView( authToken: widget.authToken),

      // Tab 1: Kehadiran / Presensi (diinjeksi authToken)
      AttendanceView(authToken: widget.authToken),

      // Tab 2: Profil Siswa
      const ProfilTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0284C7), // Biru Utama
          unselectedItemColor: const Color(0xFF94A3B8), // Abu-abu Slate
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_available_rounded),
              activeIcon: Icon(Icons.event_available_rounded),
              label: 'Kehadiran',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}