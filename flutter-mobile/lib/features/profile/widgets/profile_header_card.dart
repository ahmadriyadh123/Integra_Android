import 'dart:typed_data';

import 'package:flutter/material.dart';

class ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String className;
  final String rombel;
  final String imageUrl;
  final Uint8List? imageBytes;
  final String authToken;
  final VoidCallback? onEditTap;

  const ProfileHeaderCard({
    super.key,
    required this.name,
    required this.className,
    required this.rombel,
    required this.imageUrl,
    this.imageBytes,
    required this.authToken,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF059669);
    const Color darkSlate = Color(0xFF0F172A);
    const Color textSlate = Color(0xFF475569);

    return Column(
      children: [
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFECFDF5), width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _buildProfileImage(primaryTeal),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: darkSlate,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              rombel.isNotEmpty ? '$className • Rombel $rombel' : className,
              style: const TextStyle(
                color: textSlate,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Text(
                'AKTIF',
                style: TextStyle(
                  color: primaryTeal,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

Widget _buildProfileImage(Color fallbackColor) {
    // 1. Jika gambar dalam bentuk Uint8List (Base64 Byte dari Backend)
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      return Image.memory(
        imageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackAvatar(fallbackColor),
      );
    }

    // 2. Jika gambar dalam bentuk Network URL
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        headers: authToken != null && authToken!.isNotEmpty
            ? {'Authorization': 'Bearer $authToken'}
            : null,
        errorBuilder: (_, __, ___) => _buildFallbackAvatar(fallbackColor),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: fallbackColor,
            ),
          );
        },
      );
    }
  // 3. Fallback jika tidak ada foto profil
    return _buildFallbackAvatar(fallbackColor);
  }

  Widget _buildFallbackAvatar(Color color) {
    return Container(
      color: color.withOpacity(0.1),
      child: Icon(
        Icons.person_rounded,
        size: 48,
        color: color,
      ),
    );
  }
}
