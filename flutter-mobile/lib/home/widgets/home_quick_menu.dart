import 'package:flutter/material.dart';
import '../../kurikulum/weekly_plan/weekly_plan_view.dart';
import '../../calendar/academic_calendar_view.dart';
import '../../spmb/spmb_form_view.dart';
import '../../tagihan/tagihan_view.dart';
import '../../elearning/lesson_view.dart';
import '../../kurikulum/cbt/cbt_list_view.dart';
import '../../e-rapor/rapor_list_view.dart';
import '../../kurikulum/buku-komunikasi/buku_komunikasi_view.dart';

// Indeks tab bottom nav yang sudah ada
const int _tabKehadiran = 1;
const int _tabProfil = 2;

class QuickMenuItem {
  final String title;
  final IconData icon;
  final Color color;

  // Halaman tujuan: null berarti navigasi via tab switch
  final Widget? destination;

  // Untuk item yang cukup switch tab bottom nav
  final int? tabIndex;

  QuickMenuItem({
    required this.title,
    required this.icon,
    required this.color,
    this.destination,
    this.tabIndex,
  });
}

class HomeQuickMenu extends StatelessWidget {
  final String authToken;

  // Callback dari DashboardView
  final void Function(Widget page)? onMenuTap;
  final void Function(int index)? onTabSwitch;

  const HomeQuickMenu({
    super.key,
    required this.authToken,
    this.onMenuTap,
    this.onTabSwitch,
  });

  List<QuickMenuItem> _getMenus() {
    return [
      QuickMenuItem(
        title: 'Profil',
        icon: Icons.person,
        color: const Color(0xFF64748B),
        tabIndex: _tabProfil,
      ),
      QuickMenuItem(
        title: 'Kehadiran',
        icon: Icons.event_available_rounded,
        color: const Color(0xFF0284C7),
        tabIndex: _tabKehadiran,
      ),
      QuickMenuItem(
        title: 'E-Learning',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF0284C7),
        destination: PelajaranView(authToken: authToken),
      ),
      QuickMenuItem(
        title: 'Ujian CBT',
        icon: Icons.computer_rounded,
        color: const Color(0xFFF59E0B),
        destination: const CbtListView(),
      ),
      QuickMenuItem(
        title: 'Buku Catatan',
        icon: Icons.chat_bubble_outline_rounded,
        color: const Color(0xFF8B5CF6),
        destination: const BukuKomunikasiPage(),
      ),
      QuickMenuItem(
        title: 'Weekly Plan',
        icon: Icons.event_note_rounded,
        color: const Color(0xFF0891B2),
        destination: WeeklyPlanScreen(authToken: authToken),
      ),
      QuickMenuItem(
        title: 'Kalender',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFFEF4444),
        destination: AcademicCalendarPage(authToken: authToken),
      ),
      QuickMenuItem(
        title: 'Tagihan',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFFF97316),
        destination: TagihanPage(authToken: authToken),
      ),
      QuickMenuItem(
        title: 'E-Rapor',
        icon: Icons.assignment_turned_in_rounded,
        color: const Color(0xFF14B8A6),
        destination: RaporListViewPage(authToken: authToken),
      ),
      QuickMenuItem(
        title: 'SPMB',
        icon: Icons.person_add_alt_1_rounded,
        color: const Color(0xFF059669),
        destination: const SpmbFormScreen(),
      ),
    ];
  }

  void _handleTap(BuildContext context, QuickMenuItem menu) {
    // Jika menu punya tabIndex, switch tab di bottom nav
    if (menu.tabIndex != null) {
      onTabSwitch?.call(menu.tabIndex!);
      return;
    }

    // Jika menu punya halaman tujuan, push via nested navigator
    if (menu.destination != null) {
      if (onMenuTap != null) {
        onMenuTap!(menu.destination!);
      } else {
        // Fallback jika callback tidak tersedia
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => menu.destination!),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final menus = _getMenus();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];

        return InkWell(
          onTap: () => _handleTap(context, menu),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: menu.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  menu.icon,
                  color: menu.color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  menu.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
