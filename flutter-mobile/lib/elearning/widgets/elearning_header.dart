import 'package:flutter/material.dart';

class ElearningHeader extends StatelessWidget {
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onRefreshTap;
  final VoidCallback? onClearCacheTap;

  const ElearningHeader({
    super.key,
    this.onSearchChanged,
    this.onRefreshTap,
    this.onClearCacheTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 40, left: 8, right: 20, bottom: 24),
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
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
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
                ],
              ),
              Row(
                children: [
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
                  if (onRefreshTap != null && onClearCacheTap != null) ...[
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded,
                          color: Colors.white, size: 22),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      onSelected: (val) {
                        if (val == 'refresh' && onRefreshTap != null) {
                          onRefreshTap!();
                        } else if (val == 'clear' && onClearCacheTap != null) {
                          onClearCacheTap!();
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'refresh',
                          child: Row(
                            children: [
                              Icon(Icons.refresh_rounded,
                                  size: 18, color: Color(0xFF475569)),
                              SizedBox(width: 10),
                              Text('Perbarui dari Server',
                                  style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'clear',
                          child: Row(
                            children: [
                              Icon(Icons.delete_sweep_rounded,
                                  size: 18, color: Color(0xFFEF4444)),
                              SizedBox(width: 10),
                              Text('Hapus Cache',
                                  style: TextStyle(
                                      fontSize: 13, color: Color(0xFFEF4444))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
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
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Cari mata pelajaran atau modul...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
