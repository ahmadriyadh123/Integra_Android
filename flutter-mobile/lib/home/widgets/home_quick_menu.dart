import 'package:flutter/material.dart';
import 'package:flutter_application_1/kehadiran/view/attendance_view.dart';
import 'package:flutter_application_1/profile/profile_view.dart';
import '../../calendar/academic_calendar_view.dart';
import '../../spmb/spmb_form_view.dart';
import '../../tagihan/tagihan_view.dart';
import '../../elearning/lesson_view.dart';
import '../../kurikulum/cbt/cbt_list_view.dart';
import '../../e-rapor/rapor_detail_view.dart';
import '../../kurikulum/buku-komunikasi/buku_komunikasi_view.dart';

// 1. Buat class model data untuk mempermudah pengaturan menu
class QuickMenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final Widget destination; // <-- Di sini kita menyimpan tujuan halamannya

  QuickMenuItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.destination,
  });
}

class HomeQuickMenu extends StatelessWidget {
  const HomeQuickMenu({super.key});

  // 2. Daftar Menu & Pengaturan Navigasinya
  // Jika Anda punya halaman baru, cukup tambahkan di dalam list ini
  List<QuickMenuItem> _getMenus() {
    return [
      QuickMenuItem(
        title: 'Profil', 
        icon: Icons.person, 
        color: const Color(0xFF64748B), 
        destination: const ProfilTab()),
      QuickMenuItem(
        title: 'Kehadiran',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF0284C7), // Biru
        destination: const KehadiranTab(), // Pastikan eLearningApp sudah di-import
      ),
      QuickMenuItem(
        title: 'E-Learning',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF0284C7), // Biru
        destination: const ElearningApp(), // Pastikan eLearningApp sudah di-import
      ),
      QuickMenuItem(
        title: 'Ujian CBT',
        icon: Icons.computer_rounded,
        color: const Color(0xFFF59E0B), // Kuning Amber
        destination: const CbtListView(), // Pastikan CBTScreen sudah di-import
      ),
      QuickMenuItem(
        title: 'Buku Catatan',
        icon: Icons.chat_bubble_outline_rounded,
        color: const Color(0xFF8B5CF6), // Ungu
        destination: const BukuKomunikasiPage(), // Pastikan BukuCatatanScreen sudah di-import
      ),
      QuickMenuItem(
        title: 'Kalender',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFFEF4444), // Merah
        destination: const AcademicCalendarPage(), // Pastikan KalenderPage sudah di-import
      ),
      QuickMenuItem(
        title: 'Tagihan',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFFF97316), // Oranye
        destination: const TagihanPage(), // Pastikan TagihanPage sudah di-import 
      ),
      QuickMenuItem(
        title: 'E-Rapor',
        icon: Icons.assignment_turned_in_rounded,
        color: const Color(0xFF14B8A6), // Teal
        destination: const RaporDetailViewPage(), // Pastikan ERaporPage sudah di-import
      ),
      QuickMenuItem(
        title: 'SPMB',
        icon: Icons.person_add_alt_1_rounded,
        color: const Color(0xFF059669), // Hijau
        destination: const SpmbFormScreen(), 
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final menus = _getMenus();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true, // Agar GridView mengikuti tinggi konten
            physics: const NeverScrollableScrollPhysics(), // Matikan scroll (karena biasanya dibungkus ScrollView di luar)
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, // 4 Menu dalam satu baris
              mainAxisSpacing: 16, // Jarak vertikal antar baris
              crossAxisSpacing: 12, // Jarak horizontal antar kolom
              childAspectRatio: 0.75, // Rasio ukuran (lebar banding tinggi)
            ),
            itemCount: menus.length,
            itemBuilder: (context, index) {
              final menu = menus[index];

              return InkWell(
                // 3. DI SINI LOGIKA NAVIGASI TERJADI
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => menu.destination,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: menu.color.withValues(alpha: 0.1), // Background transparan menyesuaikan warna icon
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
          ),
        ],
      ),
    );
  }
}