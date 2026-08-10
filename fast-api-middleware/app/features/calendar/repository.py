from app.core.odoo_client import OdooRPCClient
from typing import List, Dict, Any


class CalendarRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def get_academic_calendars(self, uid: int, password: str, jenjang: str = 'sd') -> List[Dict[str, Any]]:
        """
        Ambil daftar kalender akademik berdasarkan jenjang dari model kaldik.{jenjang}.

        Tidak ada relasi langsung dari kaldik ke siswa/user, sehingga
        filter diserahkan ke ACL/Record Rule Odoo yang sudah membatasi
        akses berdasarkan kelas user yang login.
        """
        fields = [
            'id',
            'kelas_id',
            'semester_id',
            'tahun_id',
            'link_dokumen',
            'status',
        ]

        model_name = f"kaldik.{jenjang}"

        return self.odoo.search_read(
            uid=uid,
            password=password,
            model=model_name,
            domain=[],
            fields=fields,
            order='tahun_id desc, semester_id asc'
        )
