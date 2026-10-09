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
        if 'id' not in available:
            raise RuntimeError(f"Model {model_name} tidak memiliki field id.")
        class_field = next(
            (field for field in ('course_id', 'kelas_id') if field in available),
            None,
        )
        if class_field is None:
            raise RuntimeError(
                f"Model {model_name} tidak memiliki field course_id atau kelas_id; "
                "kalender tidak dapat difilter berdasarkan kelas."
            )

        requested_fields = [
            'id',
            class_field,
            *(field for field in fields if field != 'id' and field in available),
        ]

        order_fields = []
        if 'tahun_id' in available:
            order_fields.append('tahun_id desc')
        if 'semester_id' in available:
            order_fields.append('semester_id asc')

        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model=model_name,
            domain=[(class_field, '=', course_id)],
            fields=requested_fields,
            order=', '.join(order_fields) or None,
        )
        if class_field != 'course_id':
            for record in records:
                record['course_id'] = record.pop(class_field, None)
        return records
