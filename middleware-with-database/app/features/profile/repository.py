# app/features/profile/repository.py
from typing import Dict, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.core.config import settings

class ProfileRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    async def get_student_profile_record(
        self,
        user_id: int,
        partner_id: Optional[int] = None,
        student_id: Optional[int] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Mengambil data profil siswa langsung dari database berdasarkan user_id.
        """
        query = text("""
            SELECT 
                s.id,
                s.user_id,
                s.partner_id,
                p.name AS full_name,
                s.nis,
                s.nisn,
                s.gender,
                s.age,
                s.birth_place,
                s.birth_date,
                s.grade,
                s.rombel,
                c.name AS kelas_name,
                b.name AS rombel_name,
                                s.active
            FROM op_student s
            JOIN res_users u ON u.id = s.user_id
            LEFT JOIN res_partner p ON p.id = s.partner_id
                        LEFT JOIN op_course c ON c.id = s.grade
                        LEFT JOIN op_batch b ON b.id = s.rombel
                        WHERE (
                            s.id = :student_id
                            OR s.user_id = :user_id
                            OR s.partner_id = :partner_id
                        )
                            AND (s.active IS NULL OR s.active = TRUE)
                            AND u.active = TRUE
            LIMIT 1;
        """)
        
        result = await self.db.execute(
            query,
            {
                "student_id": student_id or -1,
                "user_id": user_id,
                "partner_id": partner_id or -1,
            },
        )
        row = result.mappings().first()
        return dict(row) if row else None

    async def get_partner_avatar_url(self, partner_id: int) -> Optional[str]:
        """
        Mengembalikan URL foto partner Odoo.

        Database ini tidak menyimpan kolom image_1920 di res_partner; foto
        disajikan oleh endpoint /web/image berdasarkan partner_id.
        """
        if not partner_id:
            return None
        return f"{settings.ODOO_URL}/web/image?model=res.partner&id={partner_id}&field=avatar_128"