from typing import Dict, Any, Optional
from app.features.tagihan.repository import TagihanRepository

class TagihanService:
    def __init__(self, repo: TagihanRepository):
        self.repo = repo

    def _get_status_label(self, payment_state: str) -> str:
        mapping = {
            "paid": "Lunas",
            "not_paid": "Belum Lunas",
            "partial": "Lunas Sebagian",
            "in_payment": "Dalam Proses Pembayaran"
        }
        return mapping.get(payment_state, "Belum Lunas")

    async def get_student_tagihan_summary(
        self, partner_id: int, payment_state: Optional[str] = None
    ) -> Dict[str, Any]:
        raw_invoices = await self.repo.get_student_invoices(
            partner_id=partner_id, payment_state=payment_state
        )

        total_unpaid = 0.0
        formatted_invoices = []

        for inv in raw_invoices:
            inv_id = inv.get("id")
            amount_total = float(inv.get("amount_total") or 0.0)
            amount_residual = float(inv.get("amount_residual") or 0.0)
            state_code = str(inv.get("payment_state") or "not_paid")
            total_unpaid += amount_residual

            # Ambil detail line item
            raw_lines = await self.repo.get_invoice_lines(move_id=inv_id)
            formatted_lines = []
            for line in raw_lines:
                formatted_lines.append({
                    "id": line.get("id"),
                    "product_name": str(line.get("name") or "Item Tagihan"),
                    "quantity": float(line.get("quantity") or 1.0),
                    "price_unit": float(line.get("price_unit") or 0.0),
                    "subtotal": float(line.get("price_subtotal") or 0.0)
                })

            formatted_invoices.append({
                "id": inv_id,
                "invoice_number": str(inv.get("name") or "INV/2026/001"),
                "invoice_date": str(inv.get("invoice_date") or ""),
                "due_date": str(inv.get("invoice_date_due") or ""),
                "total_amount": amount_total,
                "residual_amount": amount_residual,
                "payment_state": state_code,
                "status_label": self._get_status_label(state_code),
                "lines": formatted_lines
            })

        return {
            "total_unpaid_amount": total_unpaid,
            "total_invoices": len(formatted_invoices),
            "invoices": formatted_invoices
        }