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
    write_date: Optional[str] = None
    lines: List[InvoiceLineItemResponse] = []


class InvoiceSummaryResponse(BaseModel):
    total_unpaid_amount: float
    total_invoices: int
    invoices: List[InvoiceItemResponse]


class APIResponseInvoiceSummary(BaseModel):
    success: bool
    message: str
    data: Optional[InvoiceSummaryResponse] = None


class InvoiceSyncResponse(BaseModel):
    items: List[InvoiceItemResponse]
    removed_ids: List[int]
    all_active_ids: Optional[List[int]] = None
    next_cursor: str
    full_sync: bool


class APIResponseInvoiceSync(BaseModel):
    success: bool
    message: str
    data: InvoiceSyncResponse
