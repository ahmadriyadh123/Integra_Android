# app/features/tagihan/repository.py
from typing import List, Dict, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

class TagihanRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    async def get_student_invoices(
        self, partner_id: int, payment_state: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Mengambil faktur tagihan sekolah (Customer Invoice) berdasarkan partner_id siswa/orang tua.
        """
        query_str = """
            SELECT 
                id,
                name,
                invoice_date,
                invoice_date_due,
                amount_total,
                amount_residual,
                payment_state
            FROM account_move
            WHERE partner_id = :partner_id
              AND move_type = 'out_invoice'
              AND state = 'posted'
        """
        params = {"partner_id": partner_id}

        if payment_state:
            query_str += " AND payment_state = :payment_state"
            params["payment_state"] = payment_state

        query_str += " ORDER BY invoice_date_due DESC, id DESC;"

        result = await self.db.execute(text(query_str), params)
        return [dict(row) for row in result.mappings().all()]

    async def get_invoice_lines(self, move_id: int) -> List[Dict[str, Any]]:
        """Membaca detail rincian item tagihan (SPP, uang buku, dll) berdasarkan move_id."""
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