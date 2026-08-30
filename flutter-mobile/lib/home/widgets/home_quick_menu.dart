import 'package:flutter/material.dart';
import '../../kurikulum/weekly_plan/weekly_plan_view.dart';
import '../../calendar/academic_calendar_view.dart';
import '../../spmb/spmb_form_view.dart';
import '../../tagihan/tagihan_view.dart';
import '../../elearning/lesson_view.dart';
import '../../kurikulum/cbt/cbt_list_view.dart';
import '../../e-rapor/rapor_list_view.dart';
import '../../kurikulum/buku-komunikasi/buku_komunikasi_view.dart';
import '../../kehadiran/view/attendance_view.dart';

const int _tabProfil = 2;

class QuickMenuItem {
  final String title;
  final IconData icon;
  final Color color;

  final Widget? destination;
  final int? tabIndex;
  final String? submenu;

  QuickMenuItem({
    required this.title,
    required this.icon,
    required this.color,
    this.destination,
    this.tabIndex,
    this.submenu,
  });
}

class HomeQuickMenu extends StatefulWidget {
  final String authToken;

  final void Function(Widget page)? onMenuTap;
  final void Function(int index)? onTabSwitch;

  const HomeQuickMenu({
    super.key,
    required this.authToken,
    this.onMenuTap,
    this.onTabSwitch,
  });

  @override
  State<HomeQuickMenu> createState() => _HomeQuickMenuState();
}

class _HomeQuickMenuState extends State<HomeQuickMenu> {
  String? _expandedSubmenu;

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
        destination: AttendanceView(authToken: widget.authToken),
      ),
      QuickMenuItem(
        title: 'E-Learning',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF0284C7),
        destination: PelajaranView(authToken: widget.authToken),
      ),
      QuickMenuItem(
        title: 'Kalender',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFFEF4444),
        destination: AcademicCalendarPage(authToken: widget.authToken),
      ),
      QuickMenuItem(
        title: 'Tagihan',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFFF97316),
        destination: TagihanPage(authToken: widget.authToken),
      ),
      QuickMenuItem(
        title: 'PPDB',
        icon: Icons.edit_note_rounded,
        color: const Color(0xFF7C3AED),
        submenu: 'ppdb',
      ),
      QuickMenuItem(
        title: 'E-Rapor',
        icon: Icons.school_outlined,
        color: const Color(0xFF0D9488),
        submenu: 'rapor',
      ),
      QuickMenuItem(
        title: 'Kurikulum',
        icon: Icons.menu_book_outlined,
        color: const Color(0xFFD97706),
        submenu: 'kurikulum',
      ),
    ];
  }

  void _handleTap(BuildContext context, QuickMenuItem menu) {
    if (menu.submenu != null) {
      _toggleSubmenu(menu.submenu!);
      return;
    }

    if (menu.tabIndex != null) {
      widget.onTabSwitch?.call(menu.tabIndex!);
      return;
    }

    if (menu.destination != null) {
      if (widget.onMenuTap != null) {
        widget.onMenuTap!(menu.destination!);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => menu.destination!),
        );
      }
    }
  }

  void _toggleSubmenu(String name) {
    setState(() {
      _expandedSubmenu = _expandedSubmenu == name ? null : name;
    });
  }

  Widget _submenu(String name, String title, IconData icon, Color color,
      List<QuickMenuItem> items) {
    final isOpen = _expandedSubmenu == name;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleSubmenu(name),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  Icon(
                    isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF94A3B8),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth < 360 ? 1 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: columns == 1 ? 4.8 : 2.25,
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return OutlinedButton.icon(
                        onPressed: () => _handleTap(context, item),
                        icon: Icon(item.icon, size: 17, color: color),
                        label: Text(item.title),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menus = _getMenus();

    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'MENU UTAMA',
            style: TextStyle(
              color: Color(0xFF475569),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 360 ? 3 : 4;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 96,
              ),
              itemCount: menus.length,
              itemBuilder: (context, index) {
                final menu = menus[index];
                final hasSubmenu = menu.submenu != null;

                return InkWell(
                  onTap: () => _handleTap(context, menu),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: menu.color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          menu.icon,
                          color: menu.color,
                          size: 22,
                        ),
                      ),

                      const SizedBox(height: 7),

                      SizedBox(
                        height: 24,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            menu.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),

                      // Area indikator selalu memiliki tinggi yang sama
                      SizedBox(
                        height: 16,
                        child: hasSubmenu
                            ? Icon(
                                _expandedSubmenu == menu.submenu
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: const Color(0xFF94A3B8),
                              )
                            : null,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        const Divider(height: 24, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 10),
        _submenu('ppdb', 'PPDB', Icons.edit_note_rounded,
            const Color(0xFF7C3AED), [
          QuickMenuItem(
            title: 'STATUS',
            icon: Icons.info_outline,
            color: const Color(0xFF7C3AED),
            destination: const SpmbFormScreen(),
          ),
          QuickMenuItem(
            title: 'RIWAYAT',
            icon: Icons.history,
            color: const Color(0xFF7C3AED),
            destination: const SpmbFormScreen(),
          ),
          QuickMenuItem(
            title: 'FORMULIR',
            icon: Icons.description_outlined,
            color: const Color(0xFF7C3AED),
            destination: const SpmbFormScreen(),
          ),
        ]),
        _submenu('rapor', 'E-RAPOR', Icons.school_outlined,
            const Color(0xFF0D9488), [
          QuickMenuItem(
            title: 'DIKNAS',
            icon: Icons.description_outlined,
            color: const Color(0xFF0D9488),
            destination: RaporListViewPage(authToken: widget.authToken),
          ),
          QuickMenuItem(
            title: 'IEP',
            icon: Icons.accessibility_new_outlined,
            color: const Color(0xFF0D9488),
            destination: RaporListViewPage(authToken: widget.authToken),
          ),
        ]),
        _submenu('kurikulum', 'KURIKULUM', Icons.menu_book_outlined,
            const Color(0xFFD97706), [
          QuickMenuItem(
            title: 'WEEKLY PLAN',
            icon: Icons.folder_open_outlined,
            color: const Color(0xFFD97706),
            destination: WeeklyPlanScreen(authToken: widget.authToken),
          ),
          QuickMenuItem(
            title: 'BUKU KOMUNIKASI',
            icon: Icons.forum_outlined,
            color: const Color(0xFFD97706),
            destination: const BukuKomunikasiPage(),
          ),
          QuickMenuItem(
            title: 'CBT',
            icon: Icons.computer_outlined,
            color: const Color(0xFFD97706),
            destination: const CbtListView(),
          ),
        ]),
      ],
    );
  }
}
