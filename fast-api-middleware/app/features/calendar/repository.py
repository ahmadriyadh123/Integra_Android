from app.core.odoo_client import OdooRPCClient
from typing import List, Dict, Any

class CalendarRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def get_academic_calendars(self, uid: int, password: str) -> List[Dict[str, Any]]:
        """
        Record Rule Odoo otomatis menyaring daftar kalender akademik 
        sesuai kelas/tingkat siswa yang sedang login.
        """
        fields = [
            'kelas_id',
            'semester_id',
            'tahun_id',
            'link_dokumen'
        ]

        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='kaldik.sd',
            domain=[],  # Disaring otomatis oleh Record Rule Odoo
            fields=fields,
            order='id desc'
        )
        return records