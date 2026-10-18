from typing import Any, Dict, List, Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


_ALLOWED_LEVELS = {"sd", "smp", "tk"}
_ALLOWED_DAYS = {"senin", "selasa", "rabu", "kamis", "jumat"}


class BukuKomunikasiRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    @staticmethod
    def _table_names(jenjang: str) -> tuple[str, str, str]:
        level = jenjang.strip().lower()
        if level not in _ALLOWED_LEVELS:
            raise ValueError("Jenjang harus berupa sd, smp, atau tk.")
        return (
            f"bukpeng_{level}",
            f"bukpeng_{level}_line",
            f"bukpeng_{level}_id",
        )

    @staticmethod
    def _day_field(day: str, *, feedback: bool = False) -> str:
        normalized = day.strip().lower()
        if normalized not in _ALLOWED_DAYS:
            raise ValueError(
                "Hari tidak valid. Pilih salah satu dari: "
                "senin, selasa, rabu, kamis, jumat."
            )
        return f"feedback_{normalized}" if feedback else normalized

    async def get_buku_catatan_header(
        self, student_id: int, jenjang: str = "sd"
    ) -> Optional[Dict[str, Any]]:
        table_name, _, _ = self._table_names(jenjang)
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
            ORDER BY b.id DESC
            LIMIT 1;
        """)

        result = await self.db.execute(query, {"student_id": student_id})
        row = result.mappings().first()
        return dict(row) if row else None

    async def get_buku_catatan_lines(
        self, bukpeng_id: int, jenjang: str = "sd"
    ) -> List[Dict[str, Any]]:
        _, table_name, fk_field = self._table_names(jenjang)

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
                feedback_jumat,
                write_date
            FROM {table_name}
            WHERE {fk_field} = :bukpeng_id
            ORDER BY pekan_ke ASC, id ASC;
        """)

        result = await self.db.execute(query, {"bukpeng_id": bukpeng_id})
        return [dict(row) for row in result.mappings().all()]

    async def get_changed_lines(
        self,
        bukpeng_id: int,
        jenjang: str,
        since: "datetime",
    ) -> Dict[str, Any]:
        """
        Delta sync: hanya kembalikan line yang write_date >= since.
        Juga kembalikan semua ID aktif untuk deteksi removed di client.
        """
        from datetime import timezone
        _, table_name, fk_field = self._table_names(jenjang)
        since_utc = since.astimezone(timezone.utc).replace(tzinfo=None)

        changed_query = text(f"""
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
                feedback_jumat,
                write_date
            FROM {table_name}
            WHERE {fk_field} = :bukpeng_id
              AND write_date >= :since
            ORDER BY pekan_ke ASC, id ASC;
        """)
        changed_result = await self.db.execute(
            changed_query, {"bukpeng_id": bukpeng_id, "since": since_utc}
        )
        changed = [dict(row) for row in changed_result.mappings().all()]

        # Semua ID aktif untuk client mendeteksi removed
        all_ids_query = text(f"""
            SELECT id FROM {table_name}
            WHERE {fk_field} = :bukpeng_id
            ORDER BY id;
        """)
        all_ids_result = await self.db.execute(
            all_ids_query, {"bukpeng_id": bukpeng_id}
        )
        all_ids = [row["id"] for row in all_ids_result.mappings().all()]

        return {"changed": changed, "all_ids": all_ids}

    async def update_daily_note(
        self,
        student_id: int,
        line_id: int,
        day: str,
        note_text: str,
        jenjang: str = "sd",
    ) -> bool:
        parent_table, line_table, fk_field = self._table_names(jenjang)
        field_name = self._day_field(day)
        query = text(f"""
            UPDATE {line_table} AS line
            SET {field_name} = :note_text
            WHERE line.id = :line_id
              AND EXISTS (
                  SELECT 1
                  FROM {parent_table} AS header
                  WHERE header.id = line.{fk_field}
                    AND header.student_id = :student_id
              );
        """)

        result = await self.db.execute(
            query,
            {
                "note_text": note_text,
                "line_id": line_id,
                "student_id": student_id,
            },
        )
        if result.rowcount <= 0:
            await self.db.rollback()
            return False
        await self.db.commit()
        return result.rowcount > 0

    async def update_parent_feedback(
        self,
        student_id: int,
        line_id: int,
        day: str,
        feedback_text: str,
        jenjang: str = "sd",
    ) -> bool:
        parent_table, line_table, fk_field = self._table_names(jenjang)
        field_name = self._day_field(day, feedback=True)
        query = text(f"""
            UPDATE {line_table} AS line
            SET {field_name} = :feedback_text
            WHERE line.id = :line_id
              AND EXISTS (
                  SELECT 1
                  FROM {parent_table} AS header
                  WHERE header.id = line.{fk_field}
                    AND header.student_id = :student_id
              );
        """)
        result = await self.db.execute(
            query,
            {
                "feedback_text": feedback_text,
                "line_id": line_id,
                "student_id": student_id,
            },
        )
        if result.rowcount <= 0:
            await self.db.rollback()
            return False
        await self.db.commit()
        return True

    async def create_daily_note_line(
        self,
        student_id: int,
        pekan_ke: int,
        bulan: str,
        day: str,
        note_text: str,
        jenjang: str = "sd",
    ) -> bool:
        parent_table, line_table, fk_field = self._table_names(jenjang)
        field_name = self._day_field(day)
        query = text(f"""
            INSERT INTO {line_table}
                ({fk_field}, pekan_ke, bulan, {field_name})
            SELECT header.id, :pekan_ke, :bulan, :note_text
            FROM {parent_table} AS header
            WHERE header.student_id = :student_id
            ORDER BY header.id DESC
            LIMIT 1
            RETURNING id;
        """)
        result = await self.db.execute(
            query,
            {
                "student_id": student_id,
                "pekan_ke": pekan_ke,
                "bulan": bulan,
                "note_text": note_text,
            },
        )
        created = result.scalar_one_or_none()
        if created is None:
            await self.db.rollback()
            return False
        await self.db.commit()
        return True