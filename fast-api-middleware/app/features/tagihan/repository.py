from app.core.odoo_client import OdooRPCClient
from typing import List, Dict, Any

class TagihanRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def get_student_invoices(
        self, 
        uid: int, 
        password: str, 
        payment_state: str = None
    ) -> List[Dict[str, Any]]:
        """
        Record Rule Odoo otomatis memfilter account.move berdasarkan 
        partner_id milik siswa atau orang tua yang login!
        """
        # Batasi invoice ke customer invoice karena itu sumber tagihan siswa.
        domain = [('move_type', '=', 'out_invoice'), ('state', '=', 'posted')]

        if payment_state:
            domain.append(('payment_state', '=', payment_state))

        fields = [
            'name',
            'invoice_date',
            'invoice_date_due',
            'amount_total',
            'amount_residual',
            'payment_state',
            'invoice_line_ids'
        ]

        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='account.move',
            domain=domain,
            fields=fields,
            order='invoice_date_due desc, id desc'
        )
        return records

    def get_invoice_lines(self, uid: int, password: str, line_ids: List[int]) -> List[Dict[str, Any]]:
        """Membaca detail rincian item tagihan (spp, uang buku, dll)"""
        if not line_ids:
            return []

        fields = ['name', 'quantity', 'price_unit', 'price_subtotal']
        return self.odoo.search_read(
            uid=uid,
            password=password,
            model='account.move.line',
            domain=[('id', 'in', line_ids)],
            fields=fields,
            order='id asc'
        )