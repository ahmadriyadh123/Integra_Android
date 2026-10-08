from app.core.odoo_client import OdooRPCClient
from typing import List, Dict, Any


class CalendarRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def get_academic_calendars(
        self,
        uid: int,
        password: str,
        course_id: int,
        jenjang: str = 'sd',
    ) -> List[Dict[str, Any]]:
        """
        Ambil kalender akademik khusus kelas siswa dari model kaldik.{jenjang}.
        """
        if type(course_id) is not int or course_id <= 0:
            raise ValueError("Akun Odoo belum terhubung ke kelas siswa.")

        fields = [
            'id',
            'course_id',
            'semester_id',
            'tahun_id',
            'link_dokumen',
            'status',
        ]

        model_name = f"kaldik.{jenjang}"

        available_fields = self.odoo.execute_kw(
            uid=uid,
            password=password,
            model=model_name,
            method='fields_get',
            args=[],
            kwargs={'attributes': ['type']},
        )
        if not isinstance(available_fields, dict):
            raise RuntimeError(f"Odoo tidak mengembalikan metadata field {model_name}.")

        available = set(available_fields)
        requested_fields = [field for field in fields if field in available]
        if 'id' not in available:
            raise RuntimeError(f"Model {model_name} tidak memiliki field id.")
        if 'course_id' not in available:
            raise RuntimeError(
                f"Model {model_name} tidak memiliki field course_id; "
                "kalender tidak dapat difilter berdasarkan kelas."
            )

        order_fields = []
        if 'tahun_id' in available:
            order_fields.append('tahun_id desc')
        if 'semester_id' in available:
            order_fields.append('semester_id asc')

        return self.odoo.search_read(
            uid=uid,
            password=password,
            model=model_name,
            domain=[('course_id', '=', course_id)],
            fields=requested_fields,
            order=', '.join(order_fields) or None,
        )
