# app/features/weekly_plan/repository.py
import logging
import base64
from typing import List, Dict, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

logger = logging.getLogger(__name__)

# Mapping suffix tabel per hari
HARI_TABLE_SUFFIX = {
    'senin':  'line',
    'selasa': 'line_selasa',
    'rabu':   'line_rabu',
    'kamis':  'line_kamis',
    'jumat':  'line_jumat',
}

class WeeklyPlanRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    def _get_table_name(self, jenjang: str, suffix: str = '') -> str:
        j = jenjang.lower()
        base = f"weekly_plan_{j}" if j in ['sd', 'smp'] else "weekly_plan"
        return f"{base}_{suffix}" if suffix else base

    async def get_weekly_plans(
        self, jenjang: str = 'sd', course_id: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        """Ambil daftar weekly plan berdasarkan jenjang dan course_id."""
        table_name = self._get_table_name(jenjang)
        query_str = f"""
            SELECT 
                wp.id,
                wp.course_id,
                c.name AS course_name,
                wp.semester_id,
                sem.name AS semester_name,
                wp.tahun_ajaran_id,
                ay.name AS tahun_ajaran_name,
                wp.pekan,
                wp.status,
                wp.tema,
                wp.nama_guru
            FROM {table_name} wp
            LEFT JOIN op_course c ON c.id = wp.course_id
            LEFT JOIN op_academic_term sem ON sem.id = wp.semester_id
            LEFT JOIN op_academic_year ay ON ay.id = wp.tahun_ajaran_id
            WHERE wp.active = TRUE
        """
        params = {}
        if course_id is not None:
            query_str += " AND wp.course_id = :course_id"
            params["course_id"] = course_id

        query_str += " ORDER BY wp.id DESC;"

        result = await self.db.execute(text(query_str), params)
        return [dict(row) for row in result.mappings().all()]

    async def get_weekly_plan_by_id(
        self, plan_id: int, jenjang: str = 'sd'
    ) -> Optional[Dict[str, Any]]:
        """Ambil detail header weekly plan berdasarkan ID."""
        table_name = self._get_table_name(jenjang)
        query = text(f"""
            SELECT 
                wp.id,
                wp.nama_sekolah,
                wp.alamat_sekolah,
                wp.course_id,
                c.name AS course_name,
                wp.semester_id,
                sem.name AS semester_name,
                wp.tahun_ajaran_id,
                ay.name AS tahun_ajaran_name,
                wp.pekan,
                wp.tema,
                wp.nama_guru,
                wp.nama_kepsek,
                wp.status,
                wp.message_main_attachment_id
            FROM {table_name} wp
            LEFT JOIN op_course c ON c.id = wp.course_id
            LEFT JOIN op_academic_term sem ON sem.id = wp.semester_id
            LEFT JOIN op_academic_year ay ON ay.id = wp.tahun_ajaran_id
            WHERE wp.id = :plan_id
            LIMIT 1;
        """)
        result = await self.db.execute(query, {"plan_id": plan_id})
        row = result.mappings().first()
        return dict(row) if row else None

    async def get_attachment_pdf(self, attachment_id: int) -> Optional[bytes]:
        """Fetch binary PDF dari ir_attachment berdasarkan ID."""
        try:
            query = text("""
                SELECT datas 
                FROM ir_attachment 
                WHERE id = :attachment_id 
                LIMIT 1;
            """)
            result = await self.db.execute(query, {"attachment_id": attachment_id})
            row = result.mappings().first()
            if not row or not row.get('datas'):
                return None

            datas = row['datas']
            # Decode bytea / string base64
            if isinstance(datas, bytes):
                return datas
            return base64.b64decode(datas)
        except Exception as e:
            logger.warning(f"[weekly_plan] gagal fetch attachment id={attachment_id}: {e}")
            return None

    async def get_daily_lines(
        self, plan_id: int, hari: str, jenjang: str = 'sd'
    ) -> List[Dict[str, Any]]:
        """Ambil baris kegiatan harian dari tabel line per hari."""
        suffix = HARI_TABLE_SUFFIX.get(hari.lower(), 'line')
        table_name = self._get_table_name(jenjang, suffix)

        query = text(f"""
            SELECT id, waktu, aktivitas, media, sumber, penilaian
            FROM {table_name}
            WHERE weekly_plan_id = :plan_id
            ORDER BY id ASC;
        """)

        try:
            result = await self.db.execute(query, {"plan_id": plan_id})
            return [dict(row) for row in result.mappings().all()]
        except Exception as e:
            logger.warning(f"[weekly_plan] gagal ambil line {hari} table={table_name}: {e}")
            return []

    async def get_tp_lines(
        self, plan_id: int, jenjang: str = 'sd'
    ) -> List[Dict[str, Any]]:
        """Ambil Tujuan Pembelajaran dari tabel line_tp."""
        table_name = self._get_table_name(jenjang, 'line_tp')

        query = text(f"""
            SELECT 
                tp.id, 
                tp.subject_id, 
                sub.name AS subject_name, 
                tp.tp
            FROM {table_name} tp
            LEFT JOIN op_subject sub ON sub.id = tp.subject_id
            WHERE tp.weekly_plan_id = :plan_id
            ORDER BY tp.id ASC;
        """)

        try:
            result = await self.db.execute(query, {"plan_id": plan_id})
            return [dict(row) for row in result.mappings().all()]
        except Exception as e:
            logger.warning(f"[weekly_plan] gagal ambil tp lines table={table_name}: {e}")
            return []