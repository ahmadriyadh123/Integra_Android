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
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 18),
      decoration: const BoxDecoration(
        color: Color(0xFF059669),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Modul Pembelajaran',
                      style: TextStyle(
                        color: Color(0xFFA7F3D0),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'E-Learning Siswa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRefreshTap != null && onClearCacheTap != null)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                          Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: Color(0xFF475569),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Perbarui dari Server',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_sweep_rounded,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Hapus Cache',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
              decoration: const InputDecoration(
                hintText: 'Cari mata pelajaran atau modul...',
                hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                prefixIcon: Icon(
                  Icons.search,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
