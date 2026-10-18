from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


class TagihanRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    async def get_student_invoices(
        self, partner_id: int, payment_state: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """Ambil semua faktur (full sync)."""
        query_str = """
            SELECT
                id,
                name,
                invoice_date,
                invoice_date_due,
                amount_total,
                amount_residual,
                payment_state,
                write_date
            FROM account_move
            WHERE partner_id = :partner_id
              AND move_type = 'out_invoice'
              AND state = 'posted'
        """
        params: Dict[str, Any] = {"partner_id": partner_id}

        if payment_state:
            query_str += " AND payment_state = :payment_state"
            params["payment_state"] = payment_state

        query_str += " ORDER BY invoice_date_due DESC, id DESC;"
        result = await self.db.execute(text(query_str), params)
        return [dict(row) for row in result.mappings().all()]

    async def get_changed_invoices(
        self,
        partner_id: int,
        since: datetime,
    ) -> Dict[str, Any]:
        """
        Delta sync: hanya kembalikan faktur yang write_date >= since.
        Juga kembalikan ID faktur yang sudah tidak ada (cancelled/deleted)
        dengan membandingkan semua ID aktif terhadap yang dikirim sebelumnya.

        Kembalikan dict:
          changed : list faktur yang berubah/baru
          all_ids : semua ID faktur aktif sekarang (untuk deteksi removed di client)
        """
        since_utc = since.astimezone(timezone.utc).replace(tzinfo=None)

        # Faktur yang berubah sejak cursor
        changed_query = text("""
            SELECT
                id,
                name,
                invoice_date,
                invoice_date_due,
                amount_total,
                amount_residual,
                payment_state,
                write_date
            FROM account_move
            WHERE partner_id = :partner_id
              AND move_type = 'out_invoice'
              AND state = 'posted'
              AND write_date >= :since
            ORDER BY write_date DESC;
        """)
        changed_result = await self.db.execute(
            changed_query, {"partner_id": partner_id, "since": since_utc}
        )
        changed = [dict(row) for row in changed_result.mappings().all()]

        # Semua ID aktif — untuk client mendeteksi removed
        all_ids_query = text("""
            SELECT id
            FROM account_move
            WHERE partner_id = :partner_id
              AND move_type = 'out_invoice'
              AND state = 'posted'
            ORDER BY id;
        """)
        all_ids_result = await self.db.execute(
            all_ids_query, {"partner_id": partner_id}
        )
        all_ids = [row["id"] for row in all_ids_result.mappings().all()]

        return {"changed": changed, "all_ids": all_ids}

    async def get_invoice_lines(self, move_id: int) -> List[Dict[str, Any]]:
        """Detail rincian item tagihan per invoice."""
        query = text("""
            SELECT
                l.id,
                l.name,
                l.quantity,
                l.price_unit,
                l.price_subtotal
            FROM account_move_line l
            WHERE l.move_id = :move_id
              AND l.display_type IS NULL
            ORDER BY l.id ASC;
        """)
        result = await self.db.execute(query, {"move_id": move_id})
        return [dict(row) for row in result.mappings().all()]
