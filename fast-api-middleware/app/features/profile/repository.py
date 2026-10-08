from app.core.odoo_client import OdooRPCClient
from typing import Dict, Any, Optional

class ProfileRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def get_student_profile_record(
        self,
        uid: int,
        password: str,
        user_id: Optional[int] = None,
        partner_id: Optional[int] = None,
        student_id: Optional[int] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Record Rule Odoo otomatis memfilter op.student milik akun user_id 
        atau anak dari partner_id pengguna yang login.
        """
        available_fields = self.odoo.execute_kw(
            uid=uid,
            password=password,
            model='op.student',
            method='fields_get',
            args=[],
            kwargs={'attributes': ['type']},
        )
        if not isinstance(available_fields, dict):
            raise RuntimeError("Odoo tidak mengembalikan metadata field op.student.")
        available = set(available_fields)

        field_aliases = {
            'id': ('id',),
            'partner_id': ('partner_id',),
            'nis': ('nis', 'gr_no', 'student_code'),
            'nisn': ('nisn', 'nisn_no'),
            'birth_place': ('birth_place', 'place_of_birth'),
            'birth_date': ('birth_date', 'date_of_birth'),
            'age': ('age',),
            'grade': ('grade', 'course_id', 'class_id'),
            'rombel': ('rombel', 'batch_id', 'division_id'),
            'active': ('active',),
        }
        fields = [
            next((name for name in aliases if name in available), None)
            for aliases in field_aliases.values()
        ]
        fields = [name for name in fields if name is not None]

        domain = [('active', '=', True)] if 'active' in available else []
        if student_id:
            domain.append(('id', '=', student_id))
        elif partner_id and 'partner_id' in available:
            domain.append(('partner_id', '=', partner_id))
        elif 'user_id' in available:
            domain.append(('user_id', '=', user_id or uid))
        elif partner_id and 'partner_id' in available:
            domain.append(('partner_id', '=', partner_id))

        if 'id' not in available:
            raise RuntimeError("Model op.student tidak memiliki field id.")

        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='op.student',
            domain=domain,
            fields=fields,
            limit=1
        )
        return records[0] if records else None


    def get_partner_avatar_url(self, uid: int, password: str, partner_id: int) -> Optional[str]:
        """Membuat URL middleware untuk foto partner yang sudah tervalidasi."""
        return f"/api/v1/profile/image/{partner_id}" if partner_id else None

    def get_partner_image(
        self,
        uid: int,
        password: str,
        partner_id: int,
    ) -> Optional[Dict[str, Any]]:
        """Ambil image_1920 langsung dari res.partner melalui ORM."""
        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='res.partner',
            domain=[('id', '=', partner_id)],
            fields=['id', 'image_1920'],
            limit=1,
        )
        return records[0] if records else None