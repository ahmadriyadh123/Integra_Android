import 'package:flutter/material.dart';
import '../elearning/lesson_view.dart';
import '../home/home_view.dart';
import '../profile/profile_view.dart';
import '../kehadiran/view/attendance_view.dart';

class DashboardScreen extends StatefulWidget {
  final String studentName;
  final String studentClass;

  const DashboardScreen({
    super.key,
    required this.studentName,
    required this.studentClass,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            const HomeView(),
            const ElearningApp(),
            const KehadiranTab(),
            const ProfilTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.teal.shade700,
            unselectedItemColor: Colors.grey.shade500,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school_rounded),
                activeIcon: Icon(Icons.school_rounded),
                label: 'E-Learning',
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
