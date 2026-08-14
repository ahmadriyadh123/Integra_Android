# app/features/profile/repository.py
from typing import Dict, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.core.config import settings

class ProfileRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    async def get_student_profile_record(self, user_id: int) -> Optional[Dict[str, Any]]:
        """
        Mengambil data profil siswa langsung dari database berdasarkan user_id.
        """
        query = text("""
            SELECT 
                s.id,
                s.user_id,
                s.partner_id,
                p.name AS full_name,
                s.gr_no AS nis,
                s.nisn,
                s.gender,
                s.birth_place,
                s.birth_date,
                c.name AS kelas_name,
                b.name AS rombel_name,
                u.active
            FROM op_student s
            JOIN res_users u ON u.id = s.user_id
            LEFT JOIN res_partner p ON p.id = s.partner_id
            LEFT JOIN op_course c ON c.id = s.course_id
            LEFT JOIN op_batch b ON b.id = s.batch_id
            WHERE s.user_id = :user_id AND u.active = TRUE
            LIMIT 1;
        """)
        
        result = await self.db.execute(query, {"user_id": user_id})
        row = result.mappings().first()
        return dict(row) if row else None

    async def get_partner_avatar_url(self, partner_id: int) -> Optional[str]:
        """
        Mengambil URL foto profil siswa dari res.partner jika tersedia.
        """
        query = text("""
            SELECT image_1920 
            FROM res_partner 
            WHERE id = :partner_id
            LIMIT 1;
        """)
        result = await self.db.execute(query, {"partner_id": partner_id})
        row = result.mappings().first()
        
        if row and row.get('image_1920'):
            return f"{settings.ODOO_URL}/web/image?model=res.partner&id={partner_id}&field=avatar_128"
        return None