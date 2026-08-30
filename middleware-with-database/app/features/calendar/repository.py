from typing import List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

class CalendarRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    async def get_academic_calendars(self, jenjang: str = 'sd') -> List[Dict[str, Any]]:
        """
        Mengambil daftar kalender akademik berdasarkan jenjang langsung dari database.
        """
        table_name = f"kaldik_{jenjang.lower()}"
        
        query = text(f"""
            SELECT 
                k.id,
                c.name AS kelas_name,
                sem.name AS semester_name,
                ay.name AS tahun_name,
                k.link_dokumen,
                k.status
            FROM {table_name} k
            LEFT JOIN op_course c ON c.id = k.kelas_id
            LEFT JOIN op_academic_term sem ON sem.id = k.semester_id
            LEFT JOIN op_academic_year ay ON ay.id = k.tahun_id
            ORDER BY k.tahun_id DESC, k.semester_id ASC;
        """)
        
        result = await self.db.execute(query)
        return [dict(row) for row in result.mappings().all()]