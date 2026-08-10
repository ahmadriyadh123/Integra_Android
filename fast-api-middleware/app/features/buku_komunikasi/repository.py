from app.core.odoo_client import OdooRPCClient
from typing import Dict, Any, Optional

class BukuKomunikasiRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def get_buku_catatan_header(self, uid: int, password: str, student_id: int, jenjang: str = 'sd') -> Optional[Dict[str, Any]]:
        # 1. Ambil Header Buku Penghubung berdasarkan jenjang dan student_id
        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model=f"bukpeng.{jenjang}",
            domain=[('student_id', '=', student_id)],
            fields=['student_id', 'kelas_id', 'tahun_id', 'status'],
            limit=1
        )

        return records[0] if records else None

    def get_buku_catatan_lines(self, uid: int, password: str, bukpeng_id: int, jenjang: str = 'sd') -> list:
        fields = [
            'pekan_ke',
            'bulan',
            'senin',
            'feedback_senin',
            'selasa',
            'feedback_selasa',
            'rabu',
            'feedback_rabu',
            'kamis',
            'feedback_kamis',
            'jumat',
            'feedback_jumat',
        ]
        return self.odoo.search_read(
            uid=uid,
            password=password,
            model=f"bukpeng.{jenjang}.line",
            domain=[(f"bukpeng_{jenjang}_id", '=', bukpeng_id)],
            fields=fields,
            order='pekan_ke asc'
        )
    def update_parent_feedback(self, uid: int, password: str, line_id: int, day: str, feedback_text: str, jenjang: str = 'sd') -> bool:
        """
        Jika orang tua mencoba mengubah line milik siswa lain,
        Odoo ORM akan melemparkan AccessError secara otomatis!
        """
        field_name = f"feedback_{day.lower()}"
        return self.odoo.write(
            uid=uid,
            password=password,
            model=f"bukpeng.{jenjang}.line",
            ids=[line_id],
            values={field_name: feedback_text}
        )