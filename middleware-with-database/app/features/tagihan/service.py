from datetime import datetime, timezone, timedelta
from decimal import Decimal
from typing import Any, Dict, List, Optional

from app.features.tagihan.repository import TagihanRepository


class TagihanService:
    def __init__(self, repo: TagihanRepository):
        self.repo = repo

    @staticmethod
    def _parse_cursor(cursor: str) -> datetime:
        try:
            parsed = datetime.fromisoformat(cursor.replace("Z", "+00:00"))
        except ValueError as exc:
            raise ValueError("Cursor tagihan tidak valid.") from exc
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=timezone.utc)
        # Mundurkan 2 menit untuk toleransi clock skew
        return parsed - timedelta(minutes=2)

    @staticmethod
    def _now_watermark() -> str:
        return datetime.now(timezone.utc).isoformat()

    def _get_status_label(self, payment_state: str) -> str:
        mapping = {
            "paid": "Lunas",
            "not_paid": "Belum Lunas",
            "partial": "Lunas Sebagian",
            "in_payment": "Dalam Proses Pembayaran",
        }
        return mapping.get(payment_state, "Belum Lunas")

    async def _format_invoice(self, inv: Dict[str, Any]) -> Dict[str, Any]:
        inv_id = inv.get("id")
        amount_total = float(inv.get("amount_total") or 0.0)
        amount_residual = float(inv.get("amount_residual") or 0.0)
        state_code = str(inv.get("payment_state") or "not_paid")
        write_date = inv.get("write_date")

        raw_lines = await self.repo.get_invoice_lines(move_id=inv_id)
        formatted_lines = [
            {
                "id": line.get("id"),
                "product_name": str(line.get("name") or "Item Tagihan"),
                "quantity": float(line.get("quantity") or 1.0),
                "price_unit": float(line.get("price_unit") or 0.0),
                "subtotal": float(line.get("price_subtotal") or 0.0),
            }
            for line in raw_lines
        ]
        return {
            "id": inv_id,
            "invoice_number": str(inv.get("name") or "INV/2026/001"),
            "invoice_date": str(inv.get("invoice_date") or ""),
            "due_date": str(inv.get("invoice_date_due") or ""),
            "total_amount": amount_total,
            "residual_amount": amount_residual,
            "payment_state": state_code,
            "status_label": self._get_status_label(state_code),
            "write_date": write_date.isoformat() if hasattr(write_date, "isoformat") else str(write_date or ""),
            "lines": formatted_lines,
        }

    async def get_student_tagihan_summary(
        self, partner_id: int, payment_state: Optional[str] = None
    ) -> Dict[str, Any]:
        raw_invoices = await self.repo.get_student_invoices(
            partner_id=partner_id, payment_state=payment_state
        )
        total_unpaid = Decimal("0")
        formatted_invoices: List[Dict[str, Any]] = []
        for inv in raw_invoices:
            formatted = await self._format_invoice(inv)
            if str(inv.get("payment_state") or "not_paid") != "paid":
                residual = Decimal(str(inv.get("amount_residual") or 0))
                total_unpaid += max(residual, Decimal("0"))
            formatted_invoices.append(formatted)

        return {
            "total_unpaid_amount": float(total_unpaid),
            "total_invoices": len(formatted_invoices),
            "invoices": formatted_invoices,
        }

    async def sync_tagihan(
        self,
        partner_id: int,
        cursor: Optional[str],
    ) -> Dict[str, Any]:
        """
        Delta sync tagihan.
        - cursor=None  → full sync (ambil semua faktur)
        - cursor=<iso> → delta sync (hanya yang write_date >= cursor)
        """
        watermark = self._now_watermark()

        if cursor is None:
            # Full sync
            raw = await self.repo.get_student_invoices(partner_id=partner_id)
            items: List[Dict[str, Any]] = []
            for inv in raw:
                items.append(await self._format_invoice(inv))
            return {
                "items": items,
                "removed_ids": [],
                "next_cursor": watermark,
                "full_sync": True,
            }

        # Delta sync
        since = self._parse_cursor(cursor)
        result = await self.repo.get_changed_invoices(
            partner_id=partner_id, since=since
        )
        changed = result["changed"]
        all_active_ids: List[int] = result["all_ids"]

        items = []
        for inv in changed:
            items.append(await self._format_invoice(inv))

        # removed_ids dikembalikan agar client bisa hapus dari cache lokal
        # Client mengirim known_ids sebagai query param opsional.
        # Karena tidak ada known_ids dari client dalam request ini,
        # server tidak bisa menentukan removed_ids secara pasti.
        # Solusi: client membandingkan all_active_ids terhadap cache lokal.
        return {
            "items": items,
            "all_active_ids": all_active_ids,
            "next_cursor": watermark,
            "full_sync": False,
        }
