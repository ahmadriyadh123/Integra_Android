import 'package:flutter/material.dart';

class TokenStatusInfo extends StatelessWidget {
  const TokenStatusInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.cloud_done_rounded, color: Color(0xFF10B981), size: 16),
          SizedBox(width: 8),
          Text(
            'Server CBT Terhubung • Odoo Backend Active',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}