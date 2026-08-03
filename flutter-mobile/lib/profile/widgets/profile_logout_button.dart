import 'package:flutter/material.dart';

class ProfileLogoutButton extends StatelessWidget {
  final VoidCallback onLogoutTap;

  const ProfileLogoutButton({super.key, required this.onLogoutTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onLogoutTap,
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text(
          'Keluar dari Aplikasi',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: const Color(0xFFFEF2F2),
          foregroundColor: const Color(0xFFDC2626),
          elevation: 0,
          side: const BorderSide(color: Color(0xFFFECACA), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}