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
      // Tap tab yang sama -> pop ke root tab tersebut
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      return;
    }
    switchTab(index);
  }

  /// Menangani aksi tombol back (gesture/hardware back button)
  Future<void> _handlePopScope(bool didPop, dynamic result) async {
    if (didPop) return;

    // 1. Cek apakah ada sub-page di dalam nested Navigator yang bisa di-pop
    if (_navigatorKey.currentState != null && _navigatorKey.currentState!.canPop()) {
      _navigatorKey.currentState!.pop();
      return;
    }

    // 2. Jika sedang tidak di tab Beranda (index 0), kembalikan ke tab Beranda
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return;
    }

    // 3. Jika sudah di Beranda dan tidak ada sub-page, tampilkan dialog konfirmasi keluar
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Keluar Aplikasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      // Keluar dari aplikasi
      Navigator.of(context).pop();
    }
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
    return PopScope(
      canPop: false, // Menahan penutupan langsung aplikasi
      onPopInvokedWithResult: _handlePopScope,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        // Nested Navigator untuk body -> bottom nav selalu tampil
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
      ),
    );
  }
}