import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- Import View Tab Utama ---
import '../home/home_view.dart';
import '../kehadiran/view/attendance_view.dart';
import '../kehadiran/viewmodel/attendance_viewmodel.dart';
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

  // Navigator key untuk nested navigation di dalam body
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  static const int _attendanceTabIndex = 1;

  /// Dipakai oleh quick menu untuk switch tab bottom nav
  void switchTab(int index) {
    if (index == _attendanceTabIndex) {
      final vm = context.read<AttendanceViewModel>();
      if (!vm.isLoading && vm.filteredRecords.isEmpty && vm.errorMessage == null) {
        vm.fetchAttendance(widget.authToken);
      }
    }

    // Pop semua nested route dulu supaya kembali ke halaman utama tab
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);

    setState(() {
      _currentIndex = index;
    });
  }

  /// Dipakai oleh quick menu untuk push halaman di dalam body (bottom nav tetap tampil)
  void pushPage(Widget page) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      // Tap tab yang sama → pop ke root tab tersebut
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      return;
    }
    switchTab(index);
  }

  Widget _buildTabBody() {
    switch (_currentIndex) {
      case 0:
        return HomeView(
          authToken: widget.authToken,
          onMenuTap: pushPage,
          onTabSwitch: switchTab,
        );
      case 1:
        return AttendanceView(authToken: widget.authToken);
      case 2:
        return const ProfilTab();
      default:
        return HomeView(
          authToken: widget.authToken,
          onMenuTap: pushPage,
          onTabSwitch: switchTab,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // Nested Navigator untuk body — bottom nav selalu tampil
      body: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => _buildTabBody(),
          settings: settings,
        ),
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
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0284C7),
          unselectedItemColor: const Color(0xFF94A3B8),
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
