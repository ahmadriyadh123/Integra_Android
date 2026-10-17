import base64
import binascii
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


_LEGACY_MODELS = {
    "sd": {
        "report": "raport_siswa_sts",
        "lines": "raport_siswa_line",
        "mulok": "raport_siswa_mulok",
        "res_model": "raport.siswa.sts",
    },
    "smp": {
        "report": "raport_siswa_sts_smp",
        "lines": "raport_siswa_line_smp",
        "mulok": "raport_siswa_mulok_smp",
        "res_model": "raport.siswa.sts.smp",
    },
    "tk": {
        "report": "raport_siswa_sts_tk",
        "lines": "raport_siswa_line_tk",
        "mulok": "raport_siswa_mulok_tk",
        "res_model": "raport.siswa.sts.tk",
    },
}

_LEDGER_MODELS = {
    "sd": ("ledger_rapor_sd", "ledger_rapor_sd_lm1", "ledger.rapor.sd"),
    "smp": ("ledger_rapor_smp", "ledger_rapor_smp_lm1", "ledger.rapor.smp"),
    "tk": ("ledger_rapor_tk", "ledger_rapor_tk_lm1", "ledger.rapor.tk"),
}


class ERaporRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    @staticmethod
    def normalize_level(jenjang: Optional[str]) -> str:
        level = (jenjang or "sd").strip().lower()
        if level not in _LEGACY_MODELS:
            raise ValueError("Jenjang E-Rapor harus berupa sd, smp, atau tk.")
        return level

    async def _table_exists(self, table_name: str) -> bool:
        result = await self.db.execute(
            text("SELECT to_regclass(:table_name) AS table_name"),
            {"table_name": table_name},
        )
        row = result.mappings().first()
        return bool(row and row.get("table_name"))

    async def _columns(self, table_name: str) -> set[str]:
        result = await self.db.execute(
            text("""
                SELECT column_name
                FROM information_schema.columns
                WHERE table_schema = current_schema()
                  AND table_name = :table_name;
            """),
            {"table_name": table_name},
        )
        return {row["column_name"] for row in result.mappings().all()}

    async def _report_source(
        self, jenjang: Optional[str], student_id: Optional[int] = None
    ) -> Tuple[str, Dict[str, str]]:
        level = self.normalize_level(jenjang)
        legacy = _LEGACY_MODELS[level]
        ledger = _LEDGER_MODELS[level]
        legacy_exists = await self._table_exists(legacy["report"])
        if legacy_exists and student_id is not None:
            result = await self.db.execute(
                text(f"""
                    SELECT EXISTS(
                        SELECT 1 FROM {legacy["report"]}
                        WHERE student_id = :student_id
                    ) AS has_reports;
                """),
                {"student_id": student_id},
            )
            row = result.mappings().first()
            if row and row.get("has_reports"):
                return "legacy", legacy
        elif legacy_exists:
            return "legacy", legacy

        ledger_exists = await self._table_exists(ledger[0])
        ledger_lines_exist = await self._table_exists(ledger[1])
        if ledger_exists and ledger_lines_exist and student_id is not None:
            result = await self.db.execute(
                text(f"""
                    SELECT EXISTS(
                        SELECT 1 FROM {ledger[1]}
                        WHERE student_id = :student_id
                    ) AS has_reports;
                """),
                {"student_id": student_id},
            )
            row = result.mappings().first()
            if row and row.get("has_reports"):
                return "ledger", {
                    "report": ledger[0],
                    "lines": ledger[1],
                    "mulok": "",
                    "res_model": ledger[2],
                }
        elif ledger_exists and ledger_lines_exist:
            return "ledger", {
                "report": ledger[0],
                "lines": ledger[1],
                "mulok": "",
                "res_model": ledger[2],
            }
        if legacy_exists:
            return "legacy", legacy
        if ledger_exists and ledger_lines_exist:
            return "ledger", {
                "report": ledger[0],
                "lines": ledger[1],
                "mulok": "",
                "res_model": ledger[2],
            }
        return "legacy", legacy

    @staticmethod
    def _column(columns: set[str], alias: str, candidates: Tuple[str, ...]) -> str:
        field = next((candidate for candidate in candidates if candidate in columns), None)
        return f"{alias}.{field}" if field else "NULL"

    @staticmethod
    def _attachment_join(
        report_columns: set[str], report_alias: str, res_model: str
    ) -> str:
        conditions = [f"(att.res_model = '{res_model}' AND att.res_id = {report_alias}.id)"]
        if "message_main_attachment_id" in report_columns:
            conditions.append(
                f"att.id = {report_alias}.message_main_attachment_id"
            )
        return f"""
            LEFT JOIN LATERAL (
                SELECT att.id, att.name, att.url
                FROM ir_attachment att
                WHERE {' OR '.join(conditions)}
                ORDER BY att.id DESC
                LIMIT 1
            ) att ON TRUE
        """

    async def _get_legacy_reports(
        self,
        student_id: int,
        jenjang: str,
        report_ids: Optional[List[int]] = None,
    ) -> List[Dict[str, Any]]:
        config = _LEGACY_MODELS[jenjang]
        table = config["report"]
        columns = await self._columns(table)
        if not columns:
            return []
        if "student_id" not in columns:
            raise RuntimeError(f"Tabel {table} tidak memiliki kolom student_id.")
        if report_ids is not None and not report_ids:
            return []

        class_id = self._column(columns, "r", ("kelas_id", "grade_id"))
        year_id = self._column(columns, "r", ("tahun_pelajaran", "academic_year_id"))
        semester = self._column(columns, "r", ("semester_id", "semester"))
        report_type = self._column(columns, "r", ("jenis_raport", "jenis_rapor"))
        phase = self._column(columns, "r", ("fase", "phase"))
        average = self._column(columns, "r", ("nilai_rata_rata", "rata_rata_nilai"))
        notes = self._column(
            columns, "r", ("ksmpln_saran", "ct_kompetensi", "catatan_wali_kelas")
        )
        decision = self._column(
            columns, "r", ("keputusan_siswa", "status_keputusan")
        )
        active_filter = "AND r.active IS TRUE" if "active" in columns else ""
        id_filter = "AND r.id = ANY(:report_ids)" if report_ids is not None else ""
        class_join = (
            f"LEFT JOIN op_course c ON c.id = {class_id}"
            if class_id != "NULL"
            else ""
        )
        class_name = "c.name" if class_join else "NULL"
        year_join = (
            f"LEFT JOIN op_academic_year ay ON ay.id = {year_id}"
            if year_id != "NULL"
            else ""
        )
        year_name = "ay.name" if year_join else "NULL"

        query = text(f"""
            SELECT
                r.id,
                r.student_id,
                p.name AS student_name,
                {class_id} AS kelas_id,
                {class_name} AS kelas,
                {year_id} AS tahun_ajaran_id,
                {year_name} AS tahun_ajaran,
                {semester} AS semester,
                {report_type} AS jenis_rapor,
                {phase} AS fase,
                {average} AS rata_rata_nilai,
                {notes} AS catatan_wali_kelas,
                {decision} AS status_keputusan,
                att.id AS attachment_id,
                att.name AS file_name,
                att.url AS file_url
            FROM {table} r
            LEFT JOIN op_student s ON s.id = r.student_id
            LEFT JOIN res_partner p ON p.id = s.partner_id
            {class_join}
            {year_join}
            {self._attachment_join(columns, 'r', config['res_model'])}
            WHERE r.student_id = :student_id
              {active_filter}
              {id_filter}
            ORDER BY r.id DESC;
        """)
        params: Dict[str, Any] = {"student_id": student_id}
        if report_ids is not None:
            params["report_ids"] = report_ids
        result = await self.db.execute(query, params)
        return [dict(row) for row in result.mappings().all()]

    async def _get_ledger_reports(
        self,
        student_id: int,
        jenjang: str,
        report_ids: Optional[List[int]] = None,
    ) -> List[Dict[str, Any]]:
        if report_ids is not None and not report_ids:
            return []
        header_table, line_table, res_model = _LEDGER_MODELS[jenjang]
        id_filter = "AND l.id = ANY(:report_ids)" if report_ids is not None else ""
        query = text(f"""
            SELECT DISTINCT ON (l.id)
                l.id,
                l.student_id,
                p.name AS student_name,
                h.course_id AS kelas_id,
                c.name AS kelas,
                h.academic_year_id AS tahun_ajaran_id,
                ay.name AS tahun_ajaran,
                l.semester,
                l.jenis_rapor,
                NULL AS fase,
                COALESCE(l.nilai_rata_rata, 0) AS rata_rata_nilai,
                l.ct_kompetensi AS catatan_wali_kelas,
                NULL AS status_keputusan,
                att.id AS attachment_id,
                att.name AS file_name,
                att.url AS file_url
            FROM {line_table} l
            JOIN {header_table} h ON h.id = l.{header_table}_id
            LEFT JOIN op_student s ON s.id = l.student_id
            LEFT JOIN res_partner p ON p.id = s.partner_id
            LEFT JOIN op_course c ON c.id = h.course_id
            LEFT JOIN op_academic_year ay ON ay.id = h.academic_year_id
            LEFT JOIN LATERAL (
                SELECT a.id, a.name, a.url
                FROM ir_attachment a
                WHERE a.id = h.message_main_attachment_id
                   OR (a.res_model = :res_model AND a.res_id = h.id)
                ORDER BY a.id DESC
                LIMIT 1
            ) att ON TRUE
            WHERE l.student_id = :student_id
              {id_filter}
            ORDER BY l.id DESC, att.id DESC;
        """)
        params: Dict[str, Any] = {
            "student_id": student_id,
            "res_model": res_model,
        }
        if report_ids is not None:
            params["report_ids"] = report_ids
        result = await self.db.execute(query, params)
        return [dict(row) for row in result.mappings().all()]

    async def get_student_reports(
        self,
        student_id: int,
        jenjang: Optional[str] = None,
        report_ids: Optional[List[int]] = None,
    ) -> List[Dict[str, Any]]:
        level = self.normalize_level(jenjang)
        source, _ = await self._report_source(level, student_id)
        if source == "legacy":
            return await self._get_legacy_reports(student_id, level, report_ids)
        return await self._get_ledger_reports(student_id, level, report_ids)

    @staticmethod
    def _parse_cursor(cursor: str) -> datetime:
        try:
            parsed = datetime.fromisoformat(cursor.replace("Z", "+00:00"))
        except ValueError as exc:
            raise ValueError("Cursor E-Rapor tidak valid.") from exc
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=timezone.utc)
        return parsed.astimezone(timezone.utc).replace(tzinfo=None) - timedelta(
            minutes=2
        )

    async def _legacy_changed_ids(
        self, student_id: int, config: Dict[str, str], since: datetime
    ) -> set[int]:
        table = config["report"]
        report_columns = await self._columns(table)
        if "write_date" not in report_columns:
            raise RuntimeError(
                f"Tabel {table} tidak menyediakan write_date; "
                "sinkronisasi cursor E-Rapor tidak aman."
            )
        changed: set[int] = set()
        result = await self.db.execute(
            text(f"""
                SELECT id
                FROM {table}
                WHERE student_id = :student_id
                  AND write_date >= :since;
            """),
            {"student_id": student_id, "since": since},
        )
        changed.update(int(row["id"]) for row in result.mappings().all())

        for child_table in (config["lines"], config["mulok"]):
            if not await self._table_exists(child_table):
                continue
            child_columns = await self._columns(child_table)
            if "write_date" not in child_columns:
                raise RuntimeError(
                    f"Tabel terkait {child_table} tidak menyediakan write_date; "
                    "sinkronisasi cursor E-Rapor tidak aman."
                )
            parent_column = next(
                (
                    field
                    for field in ("raport_id", "report_id")
                    if field in child_columns
                ),
                None,
            )
            if not parent_column:
                raise RuntimeError(
                    f"Relasi {child_table} ke tabel rapor tidak dapat diverifikasi."
                )
            result = await self.db.execute(
                text(f"""
                    SELECT DISTINCT child.{parent_column} AS report_id
                    FROM {child_table} child
                    JOIN {table} report ON report.id = child.{parent_column}
                    WHERE report.student_id = :student_id
                      AND child.write_date >= :since;
                """),
                {"student_id": student_id, "since": since},
            )
            changed.update(
                int(row["report_id"])
                for row in result.mappings().all()
                if row["report_id"] is not None
            )
        return changed

    async def _ledger_changed_ids(
        self, student_id: int, jenjang: str, since: datetime
    ) -> set[int]:
        header_table, line_table, _ = _LEDGER_MODELS[jenjang]
        line_columns = await self._columns(line_table)
        header_columns = await self._columns(header_table)
        if "write_date" not in line_columns:
            raise RuntimeError(
                f"Tabel {line_table} tidak menyediakan write_date; "
                "sinkronisasi cursor E-Rapor tidak aman."
            )
        clauses = ["l.write_date >= :since"]
        if "write_date" in header_columns:
            clauses.append("h.write_date >= :since")
        result = await self.db.execute(
            text(f"""
                SELECT DISTINCT l.id AS report_id
                FROM {line_table} l
                JOIN {header_table} h ON h.id = l.{header_table}_id
                WHERE l.student_id = :student_id
                  AND ({' OR '.join(clauses)});
            """),
            {"student_id": student_id, "since": since},
        )
        return {
            int(row["report_id"])
            for row in result.mappings().all()
            if row["report_id"] is not None
        }

    async def get_student_reports_sync(
        self,
        student_id: int,
        jenjang: Optional[str],
        cursor: Optional[str],
    ) -> Dict[str, Any]:
        level = self.normalize_level(jenjang)
        watermark = datetime.now(timezone.utc).isoformat()
        if cursor is None:
            return {
                "items": await self.get_student_reports(student_id, level),
                "removed_ids": [],
                "next_cursor": watermark,
                "full_sync": True,
            }

        since = self._parse_cursor(cursor)
        source, config = await self._report_source(level, student_id)
        candidate_ids = (
            await self._legacy_changed_ids(student_id, config, since)
            if source == "legacy"
            else await self._ledger_changed_ids(student_id, level, since)
        )
        if not candidate_ids:
            return {
                "items": [],
                "removed_ids": [],
                "next_cursor": watermark,
                "full_sync": False,
            }

        items = await self.get_student_reports(
            student_id, level, sorted(candidate_ids)
        )
        current_ids = {int(item["id"]) for item in items}
        return {
            "items": items,
            "removed_ids": sorted(candidate_ids - current_ids),
            "next_cursor": watermark,
            "full_sync": False,
        }

    async def _legacy_report_detail(
        self, rapor_id: int, student_id: int, jenjang: str
    ) -> Optional[Dict[str, Any]]:
        config = _LEGACY_MODELS[jenjang]
        reports = await self._get_legacy_reports(
            student_id, jenjang, [rapor_id]
        )
        if not reports:
            return None
        report = reports[0]
        columns = await self._columns(config["report"])
        extra_fields = {
            "date": self._column(columns, "r", ("tanggal_rapor", "write_date")),
            "school": self._column(columns, "r", ("nama_sekolah",)),
            "school_address": self._column(columns, "r", ("alamat_sekolah",)),
            "teacher": (
                "teacher_partner.name"
                if "walas" in columns
                else "NULL"
            ),
        }
        teacher_join = (
            """
            LEFT JOIN res_users teacher ON teacher.id::text = r.walas::text
            LEFT JOIN res_partner teacher_partner
              ON teacher_partner.id = teacher.partner_id
            """
            if "walas" in columns
            else ""
        )
        extras_result = await self.db.execute(
            text(f"""
                SELECT
                    {extra_fields['date']} AS tanggal_pengesahan,
                    {extra_fields['school']} AS nama_sekolah,
                    {extra_fields['school_address']} AS alamat_sekolah,
                    COALESCE(
                        {extra_fields['teacher']},
                        {'NULLIF(r.walas::text, \'\')' if 'walas' in columns else 'NULL'}
                    ) AS wali_kelas
                FROM {config['report']} r
                {teacher_join}
                WHERE r.id = :rapor_id AND r.student_id = :student_id
                LIMIT 1;
            """),
            {"rapor_id": rapor_id, "student_id": student_id},
        )
        report.update(dict(extras_result.mappings().first() or {}))
        report["subjects"] = await self._get_legacy_grade_lines(
            config["lines"], rapor_id
        )
        report["muatan_lokal"] = await self._get_legacy_grade_lines(
            config["mulok"], rapor_id
        )
        report["_source"] = "legacy"
        return report

    async def _get_legacy_grade_lines(
        self, table: str, rapor_id: int
    ) -> List[Dict[str, Any]]:
        if not await self._table_exists(table):
            return []
        columns = await self._columns(table)
        parent = next(
            (field for field in ("raport_id", "report_id") if field in columns),
            None,
        )
        if parent is None:
            return []
        subject_id = self._column(columns, "line", ("subject_id",))
        score = self._column(
            columns,
            "line",
            ("nilai_akhir", "sts", "total_nilai", "nilai"),
        )
        # nilai_pengetahuan dan nilai_keterampilan hanya ada di skema lama;
        # jika tidak ada, fallback ke nilai_akhir agar tidak kosong di response.
        knowledge = self._column(columns, "line", ("sts", "nilai_akhir", "nilai"))
        skill = self._column(columns, "line", ("total_nilai", "nilai_akhir", "nilai"))
        # note  → capaian kompetensi (predikat singkat per mapel)
        # note2 → catatan kompetensi (deskripsi lengkap)
        # Fallback ke field cp_kompetensi/ct_kompetensi jika note/note2 tidak ada
        capaian = self._column(
            columns, "line", ("note", "cp_kompetensi", "predikat")
        )
        catatan = self._column(columns, "line", ("note2", "ct_kompetensi"))
        query = text(f"""
            SELECT
                line.id,
                {subject_id} AS subject_id,
                subject.name AS subject_name,
                {score} AS nilai_akhir,
                {knowledge} AS nilai_pengetahuan,
                {skill} AS nilai_keterampilan,
                {capaian} AS capaian_kompetensi,
                {catatan} AS catatan_kompetensi
            FROM {table} line
            LEFT JOIN op_subject subject ON subject.id = {subject_id}
            WHERE line.{parent} = :rapor_id
            ORDER BY line.id ASC;
        """)
        result = await self.db.execute(query, {"rapor_id": rapor_id})
        return [dict(row) for row in result.mappings().all()]

    async def _ledger_report_detail(
        self, rapor_id: int, student_id: int, jenjang: str
    ) -> Optional[Dict[str, Any]]:
        header_table, line_table, res_model = _LEDGER_MODELS[jenjang]
        reports = await self._get_ledger_reports(
            student_id, jenjang, [rapor_id]
        )
        if not reports:
            return None
        report = reports[0]
        result = await self.db.execute(
            text(f"""
                SELECT
                    l.id,
                    h.subject_id,
                    subject.name AS subject_name,
                    COALESCE(l.sts, 0) AS nilai_pengetahuan,
                    COALESCE(l.total_nilai, 0) AS nilai_keterampilan,
                    l.cp_kompetensi AS predikat
                FROM {line_table} l
                JOIN {header_table} h ON h.id = l.{header_table}_id
                LEFT JOIN op_subject subject ON subject.id = h.subject_id
                WHERE l.student_id = :student_id
                  AND l.semester = :semester
                  AND l.jenis_rapor = :jenis_rapor
                ORDER BY l.id;
            """),
            {
                "student_id": student_id,
                "semester": report.get("semester"),
                "jenis_rapor": report.get("jenis_rapor"),
            },
        )
        report["subjects"] = [dict(row) for row in result.mappings().all()]
        report["muatan_lokal"] = []
        report["fase"] = None
        report["tanggal_pengesahan"] = None
        report["wali_kelas"] = None
        report["nama_sekolah"] = None
        report["alamat_sekolah"] = None
        report["res_model"] = res_model
        report["_source"] = "ledger"
        return report

    async def get_report_card_details(
        self, rapor_id: int, student_id: int, jenjang: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        level = self.normalize_level(jenjang)
        source, _ = await self._report_source(level, student_id)
        if source == "ledger":
            detail = await self._ledger_report_detail(rapor_id, student_id, level)
            if detail:
                return detail
            if not await self._table_exists(_LEGACY_MODELS[level]["report"]):
                return None
            return await self._legacy_report_detail(rapor_id, student_id, level)
        if source == "legacy":
            detail = await self._legacy_report_detail(rapor_id, student_id, level)
            if detail:
                return detail
            if not await self._table_exists(_LEDGER_MODELS[level][0]):
                return None
        return await self._ledger_report_detail(rapor_id, student_id, level)

    async def get_student_identity(self, student_id: int) -> Dict[str, Any]:
        result = await self.db.execute(
            text("""
                SELECT s.nis, s.nisn, s.grade, s.partner_id,
                       p.name AS student_name, c.name AS kelas
                FROM op_student s
                LEFT JOIN res_partner p ON p.id = s.partner_id
                LEFT JOIN op_course c ON c.id = s.grade
                WHERE s.id = :student_id
                LIMIT 1;
            """),
            {"student_id": student_id},
        )
        row = result.mappings().first()
        return dict(row) if row else {}

    async def get_rapor_attachment(
        self,
        rapor_id: int,
        student_id: int,
        jenjang: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        level = self.normalize_level(jenjang)
        detail = await self.get_report_card_details(rapor_id, student_id, level)
        if not detail:
            return None

        attachment_id = detail.get("attachment_id")
        if attachment_id:
            result = await self.db.execute(
                text("""
                    SELECT id, name AS file_name, mimetype, store_fname, db_datas
                    FROM ir_attachment
                    WHERE id = :attachment_id
                    LIMIT 1;
                """),
                {"attachment_id": attachment_id},
            )
            row = result.mappings().first()
            if row:
                return dict(row)

        source, config = await self._report_source(level, student_id)
        if detail.get("_source") == "legacy":
            source, config = "legacy", _LEGACY_MODELS[level]
        elif detail.get("_source") == "ledger":
            source = "ledger"
        if source == "legacy":
            table = config["report"]
            model = config["res_model"]
            join = f"""
                JOIN {table} report
                  ON report.id = att.res_id
                 AND report.student_id = :student_id
            """
            where = (
                "(att.res_model = :res_model OR att.id = "
                "(SELECT message_main_attachment_id FROM "
                f"{table} WHERE id = :rapor_id AND student_id = :student_id))"
            )
            params = {
                "rapor_id": rapor_id,
                "student_id": student_id,
                "res_model": model,
            }
        else:
            header_table, line_table, model = _LEDGER_MODELS[level]
            join = f"""
                JOIN {line_table} line
                  ON line.{header_table}_id = att.res_id
                 AND line.student_id = :student_id
                JOIN {header_table} report ON report.id = line.{header_table}_id
            """
            where = "att.res_model = :res_model AND line.id = :rapor_id"
            params = {
                "rapor_id": rapor_id,
                "student_id": student_id,
                "res_model": model,
            }
        result = await self.db.execute(
            text(f"""
                SELECT att.id, att.name AS file_name, att.mimetype,
                       att.store_fname, att.db_datas
                FROM ir_attachment att
                {join}
                WHERE {where}
                ORDER BY att.id DESC
                LIMIT 1;
            """),
            params,
        )
        row = result.mappings().first()
        return dict(row) if row else None

    async def attachment_bytes(
        self, rapor_id: int, student_id: int, jenjang: Optional[str] = None
    ) -> Optional[Tuple[bytes, str]]:
        attachment = await self.get_rapor_attachment(
            rapor_id, student_id, jenjang
        )
        if not attachment:
            return None
        filename = str(attachment.get("file_name") or f"Rapor_{rapor_id}.pdf")
        if not filename.lower().endswith(".pdf"):
            filename += ".pdf"

        raw = attachment.get("db_datas")
        if isinstance(raw, memoryview):
            raw = raw.tobytes()
        if raw:
            if isinstance(raw, str):
                encoded = raw.encode("ascii")
            elif isinstance(raw, bytes):
                encoded = raw
            else:
                encoded = bytes(raw)
            if encoded.startswith(b"%PDF"):
                return encoded, filename
            try:
                decoded = base64.b64decode(encoded, validate=True)
                if decoded.startswith(b"%PDF"):
                    return decoded, filename
            except (binascii.Error, ValueError):
                pass

        store_fname = attachment.get("store_fname")
        if store_fname:
            from app.core.config import get_attachment_path

            file_path = get_attachment_path(
                str(store_fname), self.db.info.get("tenant_database")
            )
            if file_path and file_path.is_file():
                return file_path.read_bytes(), filename
        return None
