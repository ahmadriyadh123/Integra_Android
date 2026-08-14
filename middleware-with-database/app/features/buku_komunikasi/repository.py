# app/features/buku_komunikasi/repository.py
from typing import Dict, Any, Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

class BukuKomunikasiRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    async def get_buku_catatan_header(self, student_id: int, jenjang: str = 'sd') -> Optional[Dict[str, Any]]:
        """
        Mengambil header buku penghubung siswa berdasarkan jenjang dan student_id.
        """
        table_name = f"bukpeng_{jenjang.lower()}"
        query = text(f"""
            SELECT 
                b.id,
                b.student_id,
                p.name AS student_name,
                b.kelas_id,
                k.name AS kelas_name,
                b.tahun_id,
                t.name AS tahun_name,
                b.status
            FROM {table_name} b
            LEFT JOIN op_student s ON s.id = b.student_id
            LEFT JOIN res_partner p ON p.id = s.partner_id
            LEFT JOIN op_course k ON k.id = b.kelas_id
            LEFT JOIN op_academic_year t ON t.id = b.tahun_id
            WHERE b.student_id = :student_id
            LIMIT 1;
        """)
        
        result = await self.db.execute(query, {"student_id": student_id})
        row = result.mappings().first()
        return dict(row) if row else None

    async def get_buku_catatan_lines(self, bukpeng_id: int, jenjang: str = 'sd') -> List[Dict[str, Any]]:
        """
        Mengambil baris catatan harian buku komunikasi.
        """
        table_name = f"bukpeng_{jenjang.lower()}_line"
        fk_field = f"bukpeng_{jenjang.lower()}_id"
        
        query = text(f"""
            SELECT 
                id,
                pekan_ke,
                bulan,
                senin,
                feedback_senin,
                selasa,
                feedback_selasa,
                rabu,
                feedback_rabu,
                kamis,
                feedback_kamis,
                jumat,
                feedback_jumat
            FROM {table_name}
            WHERE {fk_field} = :bukpeng_id
            ORDER BY pekan_ke ASC;
        """)
        
        result = await self.db.execute(query, {"bukpeng_id": bukpeng_id})
        return [dict(row) for row in result.mappings().all()]

    async def update_parent_feedback(self, line_id: int, day: str, feedback_text: str, jenjang: str = 'sd') -> bool:
        """
        Memperbarui catatan/feedback orang tua pada hari tertentu.
        """
        table_name = f"bukpeng_{jenjang.lower()}_line"
        field_name = f"feedback_{day.lower()}"

        query = text(f"""
            UPDATE {table_name}
            SET {field_name} = :feedback_text
            WHERE id = :line_id;
        """)
        
        result = await self.db.execute(query, {"feedback_text": feedback_text, "line_id": line_id})
        await self.db.commit()
        return result.rowcount > 0