import 'package:flutter/material.dart';
import 'widgets/tagihan_summary_card.dart';
import 'widgets/tagihan_filter_row.dart';
import 'widgets/invoice_card.dart';

class TagihanPage extends StatefulWidget {
  const TagihanPage({super.key});

  @override
  State<TagihanPage> createState() => _TagihanPageState();
}

class _TagihanPageState extends State<TagihanPage> {
  static const Color primaryTeal = Color(0xFF059669);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color backgroundSlate = Color(0xFFF8FAFC);
  static const Color textSlate = Color(0xFF475569);
  static const Color borderSlate = Color(0xFFE2E8F0);

  String _selectedFilter = 'Semua';

  // Data dummy sederhana untuk keperluan presentasi UI
  final List<Map<String, dynamic>> _invoices = [
    {
      'id': 'INV/2026/07/001',
      'title': 'SPP Bulan Juli 2026',
      'category': 'SPP Bulanan',
      'dueDate': '10 Juli 2026',
      'amount': 'Rp 450.000',
      'status': 'Belum Bayar',
      'isOverdue': true,
    },
    {
      'id': 'INV/2026/07/002',
      'title': 'Buku Modul & LKS Semester 1',
      'category': 'Perlengkapan',
      'dueDate': '20 Juli 2026',
      'amount': 'Rp 300.000',
      'status': 'Belum Bayar',
      'isOverdue': false,
    },
    {
      'id': 'INV/2026/06/001',
      'title': 'SPP Bulan Juni 2026',
      'category': 'SPP Bulanan',
      'dueDate': '10 Juni 2026',
      'amount': 'Rp 450.000',
      'status': 'Lunas',
      'isOverdue': false,
      'paidDate': '08 Juni 2026',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredInvoices = _invoices.where((item) {
      if (_selectedFilter == 'Semua') return true;
      return item['status'] == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: backgroundSlate,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TagihanSummaryCard(
              totalAmount: 'Rp 750.000',
              activeCount: 2,
            ),
            const SizedBox(height: 20),
            TagihanFilterRow(
              filters: const ['Semua', 'Belum Bayar', 'Lunas'],
              selectedFilter: _selectedFilter,
              onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
            ),
            const SizedBox(height: 16),
            _buildSectionHeader(filteredInvoices.length),
            const SizedBox(height: 12),
            if (filteredInvoices.isEmpty)
              const InvoiceEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredInvoices.length,
                separatorBuilder: (context, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = filteredInvoices[index];
                  return InvoiceCard(
                    id: item['id'],
                    title: item['title'],
                    category: item['category'],
                    dueDate: item['dueDate'],
                    amount: item['amount'],
                    status: item['status'],
                    isOverdue: item['isOverdue'] ?? false,
                    paidDate: item['paidDate'],
                    onActionTap: () {},
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: darkSlate, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'INFORMASI TAGIHAN',
        style: TextStyle(
          color: darkSlate,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history_rounded, color: primaryTeal, size: 22),
          onPressed: () {},
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: borderSlate, height: 1),
      ),
    );
  }

  Widget _buildSectionHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'DAFTAR RINCIAN TAGIHAN',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: textSlate,
            letterSpacing: 0.8,
          ),
        ),
        Text(
          '$count Menampilkan',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: primaryTeal,
          ),
        ),
      ],
    );
  }
}