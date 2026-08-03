import 'package:flutter/material.dart';

class SubjectGridCard extends StatelessWidget {
  final String title;
  final String chapterCount;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const SubjectGridCard({
    super.key,
    required this.title,
    required this.chapterCount,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                chapterCount,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'Mulai Belajar',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}