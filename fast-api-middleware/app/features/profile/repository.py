from app.core.odoo_client import OdooRPCClient
from typing import Dict, Any, Optional

class ProfileRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def get_student_profile_record(self, uid: int, password: str) -> Optional[Dict[str, Any]]:
        """
        Record Rule Odoo otomatis memfilter op.student milik akun user_id 
        atau anak dari partner_id pengguna yang login.
        """
        fields = [
            'user_id',
            'partner_id',
            'nis',
            'nisn',
            'gender',
            'birth_place',
            'birth_date',
            'age',
            'unit_sekolah_id',
            'rombel',
            'active'
        ]

        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='op.student',
            domain=[('active', '=', True)],
            fields=fields,
            limit=1
        )
        return records[0] if records else None

    def get_partner_avatar_url(self, uid: int, password: str, partner_id: int) -> Optional[str]:
        """Mengambil URL foto profil siswa dari res.partner"""
        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='res.partner',
            domain=[('id', '=', partner_id)],
            fields=['image_1920'],
            limit=1
        )
        if records and records[0].get('image_1920'):
            # Return endpoint URL bawaan Odoo untuk foto partner
            return f"{self.odoo.url}/web/image?model=res.partner&id={partner_id}&field=avatar_128"
        return None