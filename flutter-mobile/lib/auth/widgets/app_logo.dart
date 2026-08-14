import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final String title;
  final String subtitle;
  final String assetPath;
  final double logoWidth;
  final double logoHeight;
  final Color textColor;
  final Color subtitleColor;

  const AppLogo({
    super.key,
    this.title = 'Selamat Datang kembali',
    this.subtitle = 'Silakan masuk ke akun Anda',
    this.assetPath = 'assets/app_icon.png',
    this.logoWidth = 80,
    this.logoHeight = 80,
    this.textColor = const Color(0xFF0F172A),
    this.subtitleColor = const Color(0xFF64748B),
  });

@override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: logoWidth,
          height: logoHeight,
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.school_rounded,
                color: const Color(0xFF059669),
                size: logoHeight,
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: subtitleColor,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}