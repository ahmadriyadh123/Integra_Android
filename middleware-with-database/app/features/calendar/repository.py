from datetime import datetime
from typing import List, Dict, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text


class CalendarRepository:
    _table_by_level = {
        "sd": "kaldik_sd",
        "smp": "kaldik_smp",
        "tk": "kaldik_tk",
    }

    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    async def get_academic_calendars(
        self, course_id: int, jenjang: str = "sd", changed_since: Optional[datetime] = None
    ) -> List[Dict[str, Any]]:
        """
        Mengambil kalender akademik untuk kelas siswa pada jenjang terkait.
        """
        if type(course_id) is not int or course_id <= 0:
            raise ValueError("Akun siswa belum terhubung ke kelas.")
        table_name = self._table_by_level.get(jenjang.lower())
        if table_name is None:
            raise ValueError(f"Jenjang kalender tidak didukung: {jenjang}.")

        query = text(f"""
            SELECT 
                k.id,
                k.kelas_id,
                c.name AS kelas_name,
                sem.name AS semester_name,
                ay.name AS tahun_name,
                k.link_dokumen,
                k.status
            FROM {table_name} k
            LEFT JOIN op_course c ON c.id = k.kelas_id
            LEFT JOIN op_academic_term sem ON sem.id = k.semester_id
            LEFT JOIN op_academic_year ay ON ay.id = k.tahun_id
            WHERE k.kelas_id = :course_id
              AND (:changed_since IS NULL OR COALESCE(k.write_date, k.create_date) >= :changed_since)
            ORDER BY k.tahun_id DESC, k.semester_id ASC;
        """)

        params = {"course_id": course_id}
        if changed_since is not None:
            params["changed_since"] = changed_since
        result = await self.db.execute(query, params)
        return [dict(row) for row in result.mappings().all()]
