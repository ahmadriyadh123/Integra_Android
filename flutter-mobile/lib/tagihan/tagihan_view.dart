import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'viewmodel/tagihan_viewmodel.dart';
import 'models/tagihan_model.dart';
import 'widgets/tagihan_summary_card.dart';
import 'widgets/tagihan_filter_row.dart';
import 'widgets/invoice_card.dart';
import '../widgets/shared_header.dart';

class TagihanPage extends StatefulWidget {
  final String authToken;

  const TagihanPage({super.key, required this.authToken});

  @override
  State<TagihanPage> createState() => _TagihanPageState();
}

class _TagihanPageState extends State<TagihanPage> {
  static const Color primaryTeal  = Color(0xFF059669);
  static const Color darkSlate    = Color(0xFF0F172A);
  static const Color bgSlate      = Color(0xFFF8FAFC);
  static const Color textSlate    = Color(0xFF475569);
  static const Color borderSlate  = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<TagihanViewModel>();
      if (!vm.isLoading && !vm.hasData && vm.errorMessage == null) {
        vm.fetchTagihan(widget.authToken);
      }
    });
  }

  // Format angka ke Rupiah
  String _formatRupiah(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer('Rp ');
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write('.');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  // Format tanggal dari "2026-07-31" ke "31 Juli 2026"
  String _formatDate(String raw) {
    if (raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSlate,
      appBar: _buildAppBar(),
      body: Consumer<TagihanViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: primaryTeal),
            );
          }
          if (vm.errorMessage != null) {
            return _buildError(vm);
          }
          if (!vm.hasData) {
            return _buildEmpty();
          }
          return _buildContent(vm);
        },
      ),
    );
  }

  Widget _buildContent(TagihanViewModel vm) {
    final summary = vm.summary!;
    final filtered = vm.filteredInvoices;

    return RefreshIndicator(
      color: primaryTeal,
      onRefresh: () => vm.fetchTagihan(widget.authToken, forceRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary card — total belum dibayar
            TagihanSummaryCard(
              totalAmount: _formatRupiah(summary.totalUnpaidAmount),
              activeCount: vm.unpaidCount,
            ),
            const SizedBox(height: 20),

            // Filter row
            TagihanFilterRow(
              filters: const ['Semua', 'Belum Lunas', 'Lunas'],
              selectedFilter: vm.selectedFilter,
              onFilterChanged: vm.setFilter,
            ),
            const SizedBox(height: 16),

            // Section header
            Row(
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
                  '${filtered.length} Menampilkan',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: primaryTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Daftar invoice
            if (filtered.isEmpty)
              const InvoiceEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, i) => _buildInvoiceCard(filtered[i]),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceItem item) {
    return InvoiceCard(
      id: item.invoiceNumber,
      title: item.invoiceNumber,
      category: item.isPaid ? 'Sudah Dibayar' : 'Belum Dibayar',
      dueDate: _formatDate(item.dueDate),
      amount: _formatRupiah(item.totalAmount),
      status: item.isPaid ? 'Lunas' : 'Belum Bayar',
      isOverdue: item.isOverdue,
      paidDate: item.isPaid ? _formatDate(item.invoiceDate) : null,
      onActionTap: () {},
    );
  }

  Widget _buildError(TagihanViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text('Gagal Memuat Tagihan',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: darkSlate)),
            const SizedBox(height: 8),
            Text(vm.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: textSlate)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => vm.fetchTagihan(widget.authToken),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 56, color: Color(0xFFCBD5E1)),
            SizedBox(height: 16),
            Text('Belum Ada Tagihan',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: darkSlate)),
            SizedBox(height: 8),
            Text('Tidak ada tagihan yang tersedia saat ini.',
                style: TextStyle(fontSize: 13, color: textSlate)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return SharedHeader(
      titleWidget: const Text(
        'INFORMASI TAGIHAN',
        style: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      centerTitle: true,
      elevation: 0,
      showBackButton: true,
      onBack: () => Navigator.pop(context),
      actions: [
        Consumer<TagihanViewModel>(
          builder: (_, vm, __) => IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: primaryTeal, size: 22),
            tooltip: 'Perbarui',
            onPressed: vm.isLoading
                ? null
                : () => vm.fetchTagihan(widget.authToken, forceRefresh: true),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: borderSlate, height: 1),
      ),
    );
  }
}
