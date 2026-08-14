import 'package:flutter/material.dart';

class ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String className;
  final String rombel;
  final String imageUrl;
  final VoidCallback? onEditTap;

  const ProfileHeaderCard({
    super.key,
    required this.name,
    required this.className,
    required this.rombel,
    required this.imageUrl,
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryTeal, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A059669),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 52,
                backgroundColor: const Color(0xFFECFDF5),
                child: ClipOval(
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: 104,
                          height: 104,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildInitialAvatar(name, primaryTeal),
                        )
                      : _buildInitialAvatar(name, primaryTeal),
                ),
              ),
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: InkWell(
                onTap: onEditTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryTeal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
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

  Widget _buildInitialAvatar(String name, Color color) {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';
    return Container(
      width: 104,
      height: 104,
      color: const Color(0xFFECFDF5),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }
}