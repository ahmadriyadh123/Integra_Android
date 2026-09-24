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
        fields = [
            'id',
            'user_id',
            'partner_id',
            'nis',
            'nisn',
            'gender',
            'birth_place',
            'birth_date',
            'age',
            'grade',
            'rombel',
            'active'
        ]

        domain = [('active', '=', True)]
        if student_id:
            domain.append(('id', '=', student_id))
        elif partner_id:
            domain.append(('partner_id', '=', partner_id))
        elif user_id or uid:
            domain.append(('user_id', '=', user_id or uid))

        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='op.student',
            domain=domain,
            fields=fields,
            limit=1,
            use_sudo=True
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
            use_sudo=True,
        )
        return records[0] if records else None