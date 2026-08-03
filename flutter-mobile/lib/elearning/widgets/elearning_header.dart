import 'package:flutter/material.dart';

class ElearningHeader extends StatelessWidget {
  final ValueChanged<String>? onSearchChanged;

  const ElearningHeader({super.key, this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF059669),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modul Pembelajaran',
                    style: TextStyle(
                      color: Color(0xFFA7F3D0),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'E-Learning Siswa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Cari mata pelajaran atau modul PDF...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}