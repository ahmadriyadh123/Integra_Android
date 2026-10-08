
from typing import List, Optional, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text


class AttendanceRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_student_id(self, student_id: int, limit: int = 100) -> List[Dict[str, Any]]:
        query = text("""
            SELECT 
                al.id,
                al.student_id,
                CONCAT(
                    COALESCE(s.first_name->>'en_US', s.first_name->>'id_ID', ''), 
                    ' ', 
                    COALESCE(s.last_name->>'en_US', s.last_name->>'id_ID', '')
                ) AS student_name,
                c.name AS course_name,
                b.name AS batch_name,
                al.attendance_date,
                al.present,
                al.excused,
                al.absent,
                al.sick,
                COALESCE(al.status, CASE WHEN al.present THEN 'hadir' WHEN al.sick THEN 'sakit' WHEN al.excused THEN 'izin' ELSE 'alfa' END) AS status,
                al.remark
            FROM op_attendance_line al
            JOIN op_student s ON s.id = al.student_id
            LEFT JOIN op_course c ON c.id = al.course_id
            LEFT JOIN op_batch b ON b.id = al.batch_id
            WHERE al.student_id = :student_id
            ORDER BY al.attendance_date DESC
            LIMIT :limit;
        """)

        result = await self.db.execute(query, {"student_id": student_id, "limit": limit})
        rows = result.mappings().all()
        return [dict(row) for row in rows]