import 'package:flutter/material.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/profile_section_card.dart';
import 'widgets/profile_logout_button.dart';

class ProfilTab extends StatelessWidget {
  const ProfilTab({super.key});

  @override
  Widget build(BuildContext context) {
    const Color backgroundSlate = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: backgroundSlate,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            ProfileHeaderCard(
              name: 'Siswa 2',
              className: 'Kelas 1 SD',
              rombel: '1A',
              imageUrl:
                  'https://images.unsplash.com/photo-1597524678053-5e6fef52d8a3?auto=format&fit=crop&q=80&w=150',
              onEditTap: () {},
            ),
            const SizedBox(height: 24),

            // Seksi 1: Data Akademik
            const ProfileSectionLabel(title: 'DATA AKADEMIK'),
            const SizedBox(height: 8),
            const ProfileSectionCard(
              children: [
                ProfileRowItem(
                  icon: Icons.perm_identity_rounded,
                  label: 'Nama Lengkap',
                  value: 'Siswa 2',
                ),
                ProfileRowItem(
                  icon: Icons.badge_outlined,
                  label: 'NIS',
                  value: '123',
                ),
                ProfileRowItem(
                  icon: Icons.badge_rounded,
                  label: 'NISN',
                  value: '3098172635',
                ),
                ProfileRowItem(
                  icon: Icons.class_outlined,
                  label: 'Kelas',
                  value: 'Kelas 1 SD',
                ),
                ProfileRowItem(
                  icon: Icons.group_work_outlined,
                  label: 'Rombel',
                  value: '1A',
                  showDivider: false,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Seksi 2: Data Pribadi
            const ProfileSectionLabel(title: 'DATA PRIBADI'),
            const SizedBox(height: 8),
            const ProfileSectionCard(
              children: [
                ProfileRowItem(
                  icon: Icons.place_outlined,
                  label: 'Tempat, Tanggal Lahir',
                  value: 'Tangerang, 01-01-2015',
                ),
                ProfileRowItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'Umur',
                  value: '11y 2m 15d',
                  showDivider: false,
                ),
              ],
            ),

            const SizedBox(height: 32),
            ProfileLogoutButton(
              onLogoutTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}