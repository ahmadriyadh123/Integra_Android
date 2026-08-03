import 'package:flutter/material.dart';
import 'detail_course_view.dart';
import 'widgets/elearning_header.dart';
import 'widgets/active_course_card.dart';
import 'widgets/subject_grid_card.dart';

void main() {
  runApp(const ElearningApp());
}

class ElearningApp extends StatelessWidget {
  const ElearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Learning Sekolah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Plus Jakarta Sans',
        primaryColor: const Color(0xFF059669),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF059669),
          primary: const Color(0xFF059669),
          secondary: const Color(0xFFF59E0B),
        ),
      ),
      home: const PelajaranView(),
    );
  }
}

class PelajaranView extends StatelessWidget {
  const PelajaranView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ElearningHeader(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    title: 'Sedang Dipelajari',
                    icon: Icons.menu_book,
                    badgeText: 'Aktif',
                  ),
                  const SizedBox(height: 12),
                  ActiveCourseCard(
                    title: 'Matematika Wajib',
                    teacher: 'Bpk. Hendra, S.Pd • Bab 2',
                    progress: 0.65,
                    icon: Icons.functions,
                    iconBgColor: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF2563EB),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DetailCourseView(
                            title: 'Matematika Wajib',
                            teacher: 'Bpk. Hendra, S.Pd',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  ActiveCourseCard(
                    title: 'Fisika',
                    teacher: 'Ibu Siska, M.Pd • Bab 1',
                    progress: 0.30,
                    icon: Icons.science,
                    iconBgColor: const Color(0xFFFFF1F2),
                    iconColor: const Color(0xFFE11D48),
                    onTap: () {},
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.grid_view_rounded, size: 18, color: Color(0xFF059669)),
                          SizedBox(width: 8),
                          Text(
                            'Semua Mata Pelajaran',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Total 6 Mapel',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.88,
                    children: [
                      SubjectGridCard(
                        title: 'Biologi',
                        chapterCount: '10 Bab Modul',
                        icon: Icons.eco_outlined,
                        iconBgColor: const Color(0xFFECFDF5),
                        iconColor: const Color(0xFF059669),
                        onTap: () {},
                      ),
                      SubjectGridCard(
                        title: 'Sejarah',
                        chapterCount: '8 Bab Modul',
                        icon: Icons.public,
                        iconBgColor: const Color(0xFFFFF7ED),
                        iconColor: const Color(0xFFEA580C),
                        onTap: () {},
                      ),
                      SubjectGridCard(
                        title: 'B. Inggris',
                        chapterCount: '12 Bab Modul',
                        icon: Icons.translate,
                        iconBgColor: const Color(0xFFF0FDFA),
                        iconColor: const Color(0xFF0D9488),
                        onTap: () {},
                      ),
                      SubjectGridCard(
                        title: 'Informatika',
                        chapterCount: '6 Bab Modul',
                        icon: Icons.computer,
                        iconBgColor: const Color(0xFFF0F9FF),
                        iconColor: const Color(0xFF0284C7),
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required String badgeText,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF059669)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            badgeText,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF059669),
            ),
          ),
        ),
      ],
    );
  }
}