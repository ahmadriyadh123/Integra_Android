import 'package:flutter/material.dart';

class TagihanSummaryCard extends StatelessWidget {
  final String totalAmount;
  final int activeCount;
  final VoidCallback? onPaymentMethodTap;

  const TagihanSummaryCard({
    super.key,
    required this.totalAmount,
    required this.activeCount,
    this.onPaymentMethodTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26059669),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL TAGIHAN BELUM DIBAYAR',
                style: TextStyle(
                  color: Color(0xFFA7F3D0),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$activeCount Tagihan Aktif',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            totalAmount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFFA7F3D0), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Virtual Account & QRIS Tersedia',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onPaymentMethodTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Cara Bayar',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}