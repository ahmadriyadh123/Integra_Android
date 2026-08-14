# app/features/tagihan/schemas.py
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
    invoice_number: str
    invoice_date: str
    due_date: str
    total_amount: float
    residual_amount: float
    payment_state: str
    status_label: str
    lines: List[InvoiceLineItemResponse] = []

class InvoiceSummaryResponse(BaseModel):
    total_unpaid_amount: float
    total_invoices: int
    invoices: List[InvoiceItemResponse]

class APIResponseInvoiceSummary(BaseModel):
    success: bool
    message: str
    data: Optional[InvoiceSummaryResponse] = None