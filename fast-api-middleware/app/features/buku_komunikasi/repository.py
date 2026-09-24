from app.core.odoo_client import OdooRPCClient
from typing import Dict, Any, Optional

class BukuKomunikasiRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def get_buku_catatan_header(self, uid: int, password: str, student_id: int, jenjang: str = 'sd') -> Optional[Dict[str, Any]]:
        # Header menentukan buku penghubung yang dimiliki siswa.
        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model=f"bukpeng.{jenjang}",
            domain=[('student_id', '=', student_id)],
            fields=['id', 'student_id', 'kelas_id', 'tahun_id', 'status'],
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

    def create_daily_note_line(self, uid: int, password: str, bukpeng_id: int, pekan_ke: int, bulan: str, day: str, note_text: str, jenjang: str = 'sd') -> bool:
        """
        Membuat baris pekan baru (bukpeng.<jenjang>.line) jika belum ada di Odoo,
        sekaligus mengisi catatan harian pertama.
        """
        field_name = day.lower()
        values = {
            f"bukpeng_{jenjang}_id": bukpeng_id,
            "pekan_ke": pekan_ke,
            "bulan": bulan,
            field_name: note_text
        }
        
        created_id = self.odoo.create(
            uid=uid,
            password=password,
            model=f"bukpeng.{jenjang}.line",
            values=values
        )
        return bool(created_id)

    def update_daily_note(self, uid: int, password: str, line_id: int, day: str, note_text: str, jenjang: str = 'sd') -> bool:
        """
        Memperbarui catatan harian pada baris pekan yang sudah ada.
        """
        field_name = day.lower()
        return self.odoo.write(
            uid=uid,
            password=password,
            model=f"bukpeng.{jenjang}.line",
            ids=[line_id],
            values={field_name: note_text}
        )