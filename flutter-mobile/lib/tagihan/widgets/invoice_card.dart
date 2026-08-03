import 'package:flutter/material.dart';

class InvoiceCard extends StatelessWidget {
  final String id;
  final String title;
  final String category;
  final String dueDate;
  final String amount;
  final String status;
  final bool isOverdue;
  final String? paidDate;
  final VoidCallback? onActionTap;

  const InvoiceCard({
    super.key,
    required this.id,
    required this.title,
    required this.category,
    required this.dueDate,
    required this.amount,
    required this.status,
    this.isOverdue = false,
    this.paidDate,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF059669);
    const Color darkSlate = Color(0xFF0F172A);
    const Color textSlate = Color(0xFF475569);
    const Color borderSlate = Color(0xFFE2E8F0);
    const Color redAlert = Color(0xFFDC2626);
    const Color amberWarning = Color(0xFFD97706);

    final isLunas = status == 'Lunas';
    final accentColor = isLunas
        ? primaryTeal
        : (isOverdue ? redAlert : amberWarning);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderSlate),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: accentColor, width: 5),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 16, color: accentColor),
                      const SizedBox(width: 6),
                      Text(
                        id,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: textSlate,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isLunas
                          ? 'LUNAS'
                          : (isOverdue ? 'JATUH TEMPO' : 'BELUM BAYAR'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: darkSlate,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kategori: $category',
                style: const TextStyle(fontSize: 11, color: textSlate),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLunas
                            ? 'Dibayar pada: $paidDate'
                            : 'Batas Waktu: $dueDate',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isOverdue && !isLunas ? redAlert : textSlate,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        amount,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: darkSlate,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: onActionTap,
                    icon: Icon(
                      isLunas
                          ? Icons.download_rounded
                          : Icons.account_balance_wallet_rounded,
                      size: 16,
                    ),
                    label: Text(
                      isLunas ? 'Kwitansi' : 'Bayar Sekarang',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLunas ? const Color(0xFFF1F5F9) : primaryTeal,
                      foregroundColor: isLunas ? darkSlate : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InvoiceEmptyState extends StatelessWidget {
  const InvoiceEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.task_alt_rounded, size: 48, color: Color(0xFF059669)),
          SizedBox(height: 12),
          Text(
            'Tidak Ada Tagihan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Semua tagihan pada kategori ini sudah bersih.',
            style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
}