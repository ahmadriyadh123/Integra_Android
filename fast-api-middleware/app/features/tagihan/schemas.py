from pydantic import BaseModel
from typing import List, Optional

class InvoiceLineItemResponse(BaseModel):
    id: int
    product_name: str
    quantity: float
    price_unit: float
    subtotal: float

class InvoiceItemResponse(BaseModel):
    id: int
    invoice_number: str         # Nomor Faktur (misal: "INV/2026/001")
    invoice_date: str           # Tanggal Terbit
    due_date: str               # Jatuh Tempo
    total_amount: float         # Total Tagihan
    residual_amount: float      # Sisa Tagihan yang Harus Dibayar
    payment_state: str          # 'not_paid', 'paid', 'partial', 'in_payment'
    status_label: str           # "Belum Lunas", "Lunas", "Lunas Sebagian"
    lines: List[InvoiceLineItemResponse] = []

class InvoiceSummaryResponse(BaseModel):
    total_unpaid_amount: float
    total_invoices: int
    invoices: List[InvoiceItemResponse]

class APIResponseInvoiceSummary(BaseModel):
    success: bool
    message: str
    data: Optional[InvoiceSummaryResponse] = None