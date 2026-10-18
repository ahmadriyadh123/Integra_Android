class InvoiceLineItem {
  final int id;
  final String productName;
  final double quantity;
  final double priceUnit;
  final double subtotal;

  InvoiceLineItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.priceUnit,
    required this.subtotal,
  });

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItem(
      id: json['id'] as int,
      productName: json['product_name'] as String? ?? '-',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      priceUnit: (json['price_unit'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class InvoiceItem {
  final int id;
  final String invoiceNumber;
  final String invoiceDate;
  final String dueDate;
  final double totalAmount;
  final double residualAmount;
  final String paymentState;
  final String statusLabel;
  final String? writeDate;
  final List<InvoiceLineItem> lines;

  InvoiceItem({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.totalAmount,
    required this.residualAmount,
    required this.paymentState,
    required this.statusLabel,
    this.writeDate,
    required this.lines,
  });

  bool get isPaid => paymentState == 'paid';
  bool get isOverdue {
    if (isPaid || dueDate.isEmpty) return false;
    try {
      final due = DateTime.parse(dueDate);
      return DateTime.now().isAfter(due);
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoice_number': invoiceNumber,
        'invoice_date': invoiceDate,
        'due_date': dueDate,
        'total_amount': totalAmount,
        'residual_amount': residualAmount,
        'payment_state': paymentState,
        'status_label': statusLabel,
        'write_date': writeDate,
        'lines': lines.map((l) => {
          'id': l.id,
          'product_name': l.productName,
          'quantity': l.quantity,
          'price_unit': l.priceUnit,
          'subtotal': l.subtotal,
        }).toList(),
      };

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List<dynamic>? ?? [];
    return InvoiceItem(
      id: json['id'] as int,
      invoiceNumber: json['invoice_number'] as String? ?? '-',
      invoiceDate: json['invoice_date'] as String? ?? '',
      dueDate: json['due_date'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      residualAmount: (json['residual_amount'] as num?)?.toDouble() ?? 0.0,
      paymentState: json['payment_state'] as String? ?? 'not_paid',
      statusLabel: json['status_label'] as String? ?? 'Belum Lunas',
      writeDate: json['write_date'] as String?,
      lines: rawLines
          .map((e) => InvoiceLineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TagihanSummary {
  final double totalUnpaidAmount;
  final int totalInvoices;
  final List<InvoiceItem> invoices;

  TagihanSummary({
    required this.totalUnpaidAmount,
    required this.totalInvoices,
    required this.invoices,
  });

  factory TagihanSummary.fromJson(Map<String, dynamic> json) {
    final rawInvoices = json['invoices'] as List<dynamic>? ?? [];
    return TagihanSummary(
      totalUnpaidAmount:
          (json['total_unpaid_amount'] as num?)?.toDouble() ?? 0.0,
      totalInvoices: json['total_invoices'] as int? ?? 0,
      invoices: rawInvoices
          .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
