"""Repository untuk polling notifikasi berdasarkan perubahan data di tabel fitur.

Endpoint GET /notifications menerima cursor (ISO timestamp) dan student_id,
lalu memeriksa tabel-tabel fitur untuk record dengan create_date/write_date
lebih baru dari cursor yang relevan untuk siswa tersebut.
"""

import logging
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

logger = logging.getLogger(__name__)


class NotificationRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    # ── Helper: parse cursor ────────────────────────────────────────────────────

    @staticmethod
    def parse_cursor(cursor: Optional[str]) -> datetime:
        if cursor is None:
            return datetime.now(timezone.utc) - timedelta(days=30)
        try:
            parsed = datetime.fromisoformat(cursor.replace("Z", "+00:00"))
        except ValueError as exc:
            raise ValueError("Cursor notifikasi tidak valid.") from exc
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=timezone.utc)
        return parsed.astimezone(timezone.utc).replace(tzinfo=None) - timedelta(
            minutes=2
        )

    @staticmethod
    def _now_watermark() -> str:
        return datetime.now(timezone.utc).isoformat()

    # ── Cek tabel yang ada ──────────────────────────────────────────────────────

    async def _table_exists(self, table_name: str) -> bool:
        result = await self.db.execute(
            text("SELECT to_regclass(:t) AS t"),
            {"t": table_name},
        )
        row = result.mappings().first()
        return bool(row and row.get("t"))

    # ── Query per kategori ──────────────────────────────────────────────────────

    async def check_rapor(
        self, student_id: int, since: datetime
    ) -> List[Dict[str, Any]]:
        if not await self._table_exists("raport_siswa_sts"):
            return []
        query = text("""
            SELECT
                r.id           AS ref_id,
                r.jenis_raport AS judul,
                'Rapor ' || r.jenis_raport
                    || ' semester ' || r.semester_id
                    || ' telah tersedia' AS isi,
                r.create_date  AS created_at
            FROM raport_siswa_sts r
            WHERE r.student_id = :student_id
              AND r.active = TRUE
              AND r.create_date >= :since
            ORDER BY r.create_date DESC
            LIMIT 20;
        """)
        try:
            result = await self.db.execute(
                query, {"student_id": student_id, "since": since}
            )
            return [dict(row) for row in result.mappings().all()]
        except Exception as exc:
            logger.warning("[notification] gagal cek rapor: %s", exc)
            return []

    async def check_weekly_plan(
        self, student_id: int, since: datetime, jenjang: str = "sd"
    ) -> List[Dict[str, Any]]:
        table = f"weekly_plan_{jenjang}" if jenjang in ("sd", "smp") else "weekly_plan"
        if not await self._table_exists(table):
            return []
        fk_course = "course_id"
        query = text(f"""
            SELECT
                wp.id           AS ref_id,
                'Weekly Plan pekan ' || wp.pekan AS judul,
                'Rencana pembelajaran untuk pekan ' || wp.pekan
                    || ' telah diterbitkan' AS isi,
                wp.create_date  AS created_at
            FROM {table} wp
            WHERE wp.active = TRUE
              AND wp.create_date >= :since
            ORDER BY wp.create_date DESC
            LIMIT 20;
        """)
        try:
            result = await self.db.execute(query, {"since": since})
            return [dict(row) for row in result.mappings().all()]
        except Exception as exc:
            logger.warning("[notification] gagal cek weekly_plan: %s", exc)
            return []

    async def check_weekly_plan_status(
        self, student_id: int, since: datetime, jenjang: str = "sd"
    ) -> List[Dict[str, Any]]:
        table = f"weekly_plan_{jenjang}" if jenjang in ("sd", "smp") else "weekly_plan"
        if not await self._table_exists(table):
            return []
        query = text(f"""
            SELECT
                wp.id           AS ref_id,
                'Status Weekly Plan pekan ' || wp.pekan AS judul,
                'Rencana pembelajaran pekan ' || wp.pekan
                    || ' berstatus: ' || wp.status AS isi,
                wp.write_date   AS created_at
            FROM {table} wp
            WHERE wp.active = TRUE
              AND wp.write_date >= :since
              AND wp.status IN ('rejected', 'approved')
              AND wp.create_date < :since
            ORDER BY wp.write_date DESC
            LIMIT 10;
        """)
        try:
            result = await self.db.execute(query, {"since": since})
            return [dict(row) for row in result.mappings().all()]
        except Exception as exc:
            logger.warning("[notification] gagal cek weekly_plan status: %s", exc)
            return []

    async def check_buku_komunikasi(
        self, student_id: int, since: datetime
    ) -> List[Dict[str, Any]]:
        if not await self._table_exists("raport_siswa_line"):
            return []
        query = text("""
            SELECT
                line.id         AS ref_id,
                subj.name       AS judul,
                LEFT(line.note, 200) AS isi,
                line.create_date AS created_at
            FROM raport_siswa_line line
            LEFT JOIN op_subject subj ON subj.id = line.subject_id
            LEFT JOIN raport_siswa_sts r ON r.id = line.raport_id
            WHERE r.student_id = :student_id
              AND r.active = TRUE
              AND line.create_date >= :since
              AND line.raport_id IS NOT NULL
            ORDER BY line.create_date DESC
            LIMIT 20;
        """)
        try:
            result = await self.db.execute(
                query, {"student_id": student_id, "since": since}
            )
            return [dict(row) for row in result.mappings().all()]
        except Exception as exc:
            logger.warning("[notification] gagal cek buku_komunikasi: %s", exc)
            return []

    async def check_assignment(
        self, student_id: int, since: datetime, course_id: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        if not await self._table_exists("assignment_assignment"):
            return []
        course_filter = "AND a.course_id = :course_id" if course_id else ""
        query = text(f"""
            SELECT
                a.id            AS ref_id,
                a.name          AS judul,
                'Tugas baru: ' || a.name || ' telah diberikan' AS isi,
                a.create_date   AS created_at
            FROM assignment_assignment a
            WHERE a.active = TRUE
              AND a.create_date >= :since
              {course_filter}
            ORDER BY a.create_date DESC
            LIMIT 20;
        """)
        params: Dict[str, Any] = {"since": since}
        if course_id:
            params["course_id"] = course_id
        try:
            result = await self.db.execute(query, params)
            return [dict(row) for row in result.mappings().all()]
        except Exception as exc:
            logger.warning("[notification] gagal cek assignment: %s", exc)
            return []

    async def check_attendance(
        self, student_id: int, since: datetime
    ) -> List[Dict[str, Any]]:
        if not await self._table_exists("op_attendance_line"):
            return []
        query = text("""
            SELECT
                al.id           AS ref_id,
                'Catatan kehadiran baru' AS judul,
                CASE
                    WHEN al.present = FALSE AND al.absent = TRUE
                        THEN 'Anda tercatat tidak hadir.'
                    WHEN al.sick = TRUE
                        THEN 'Anda tercatat sakit.'
                    WHEN al.leave = TRUE
                        THEN 'Anda tercatat izin.'
                    ELSE 'Status kehadiran diperbarui.'
                END AS isi,
                al.write_date   AS created_at
            FROM op_attendance_line al
            WHERE al.student_id = :student_id
              AND al.write_date >= :since
            ORDER BY al.write_date DESC
            LIMIT 20;
        """)
        try:
            result = await self.db.execute(
                query, {"student_id": student_id, "since": since}
            )
            return [dict(row) for row in result.mappings().all()]
        except Exception as exc:
            logger.warning("[notification] gagal cek attendance: %s", exc)
            return []

    # ── Aggregate ───────────────────────────────────────────────────────────────

    async def get_notifications(
        self,
        student_id: int,
        cursor: Optional[str] = None,
        jenjang: str = "sd",
        course_id: Optional[int] = None,
    ) -> Dict[str, Any]:
        since = self.parse_cursor(cursor)
        watermark = self._now_watermark()

        categories: List[Dict[str, Any]] = []

        rapor = await self.check_rapor(student_id, since)
        for r in rapor:
            categories.append({**r, "kategori": "rapor"})

        wp = await self.check_weekly_plan(student_id, since, jenjang)
        for r in wp:
            categories.append({**r, "kategori": "weekly_plan"})

        wp_status = await self.check_weekly_plan_status(student_id, since, jenjang)
        for r in wp_status:
            categories.append({**r, "kategori": "weekly_plan"})

        buku = await self.check_buku_komunikasi(student_id, since)
        for r in buku:
            categories.append({**r, "kategori": "buku_komunikasi"})

        assignment = await self.check_assignment(student_id, since, course_id)
        for r in assignment:
            categories.append({**r, "kategori": "assignment"})

        attendance = await self.check_attendance(student_id, since)
        for r in attendance:
            categories.append({**r, "kategori": "attendance"})

        # Sort semua berdasarkan created_at DESC
        categories.sort(key=lambda x: x.get("created_at") or datetime.min, reverse=True)

        return {
            "items": categories,
            "next_cursor": watermark,
            "full_sync": cursor is None,
        }
