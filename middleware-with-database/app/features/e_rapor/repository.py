from typing import List, Dict, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

class ERaporRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    async def get_student_level_from_course(self, student_id: int) -> Optional[str]:
        query = text("""
            SELECT LOWER(c.name) AS course_name
            FROM op_student_course sc
            JOIN op_course c ON c.id = sc.course_id
            WHERE sc.student_id = :student_id
            ORDER BY sc.id DESC
            LIMIT 1;
        """)
        result = await self.db.execute(query, {"student_id": student_id})
        row = result.mappings().first()
        if not row or not row["course_name"]:
            return "sd"  # Default fallback ke SD jika tidak ditemukan
            
        course_name = row["course_name"]
        if "smp" in course_name:
            return "smp"
        elif "sd" in course_name:
            return "sd"
        elif "tk" in course_name or "paud" in course_name:
            return "tk"
        return "sd"

    async def get_student_reports(self, student_id: int) -> List[Dict[str, Any]]:
        level = await self.get_student_level_from_course(student_id)
        if level == 'sd':
            header_table, line_table, res_model_name = "ledger_rapor_sd", "ledger_rapor_sd_lm1", "ledger.rapor.sd"
        elif level == 'smp':
            header_table, line_table, res_model_name = "ledger_rapor_smp", "ledger_rapor_smp_lm1", "ledger.rapor.smp"
        elif level == 'tk':
            header_table, line_table, res_model_name = "ledger_rapor_tk", "ledger_rapor_tk_lm1", "ledger.rapor.tk"
        else:
            return []

        fk_col = f"{header_table}_id"

        query = text(f"""
            SELECT DISTINCT ON (l.id)
                l.id,
                l.student_id,
                p.name AS student_name,
                h.course_id AS kelas_id,
                c.name AS kelas_name,
                l.semester,
                l.jenis_rapor,
                h.academic_year_id AS tahun_ajaran_id,
                ay.name AS tahun_ajaran_name,
                l.nilai_rata_rata,
                l.ct_kompetensi AS catatan_wali_kelas,
                att.id AS attachment_id,
                att.name AS file_name,
                att.mimetype,
                att.store_fname,
                att.url AS file_url
            FROM {line_table} l
            JOIN {header_table} h ON h.id = l.{fk_col}
            LEFT JOIN op_student s ON s.id = l.student_id
            LEFT JOIN res_partner p ON p.id = s.partner_id
            LEFT JOIN op_course c ON c.id = h.course_id
            LEFT JOIN op_academic_year ay ON ay.id = h.academic_year_id
            LEFT JOIN ir_attachment att ON (
                att.id = h.message_main_attachment_id
                OR (att.res_model = :res_model AND att.res_id = h.id)
            )
            WHERE l.student_id = :student_id
            ORDER BY l.id DESC;
        """)
        result = await self.db.execute(query, {"student_id": student_id, "res_model": res_model_name})
        return [dict(row) for row in result.mappings().all()]

    async def get_report_card_details(self, rapor_id: int, student_id: int) -> Optional[Dict[str, Any]]:
        level = await self.get_student_level_from_course(student_id)
        if level == 'sd':
            header_table, line_table, res_model_name = "ledger_rapor_sd", "ledger_rapor_sd_lm1", "ledger.rapor.sd"
        elif level == 'smp':
            header_table, line_table, res_model_name = "ledger_rapor_smp", "ledger_rapor_smp_lm1", "ledger.rapor.smp"
        elif level == 'tk':
            header_table, line_table, res_model_name = "ledger_rapor_tk", "ledger_rapor_tk_lm1", "ledger.rapor.tk"
        else:
            return None

        fk_col = f"{header_table}_id"

        query_header = text(f"""
            SELECT
                l.id,
                l.student_id,
                p.name AS student_name,
                h.course_id AS kelas_id,
                c.name AS kelas_name,
                l.semester,
                l.jenis_rapor,
                ay.name AS tahun_ajaran_name,
                l.nilai_rata_rata,
                l.ct_kompetensi AS catatan_wali_kelas,
                att.id AS attachment_id,
                att.name AS file_name,
                att.mimetype,
                att.store_fname,
                att.url AS file_url
            FROM {line_table} l
            JOIN {header_table} h ON h.id = l.{fk_col}
            LEFT JOIN op_student s ON s.id = l.student_id
            LEFT JOIN res_partner p ON p.id = s.partner_id
            LEFT JOIN op_course c ON c.id = h.course_id
            LEFT JOIN op_academic_year ay ON ay.id = h.academic_year_id
            LEFT JOIN ir_attachment att ON (
                att.id = h.message_main_attachment_id
                OR (att.res_model = :res_model AND att.res_id = h.id)
            )
            WHERE l.id = :rapor_id AND l.student_id = :student_id
            LIMIT 1;
        """)
        res_header = await self.db.execute(
            query_header,
            {"rapor_id": rapor_id, "student_id": student_id, "res_model": res_model_name}
        )
        report = res_header.mappings().first()
        if not report:
            return None

        report_dict = dict(report)

        # Mengambil daftar nilai mata pelajaran siswa pada semester & jenis rapor yang sama
        query_subjects = text(f"""
            SELECT
                l.id,
                h.subject_id,
                sub.name AS subject_name,
                COALESCE(l.sts, 0) AS nilai_pengetahuan,
                COALESCE(l.total_nilai, 0) AS nilai_keterampilan,
                l.cp_kompetensi AS predikat
            FROM {line_table} l
            JOIN {header_table} h ON h.id = l.{fk_col}
            LEFT JOIN op_subject sub ON sub.id = h.subject_id
            WHERE l.student_id = :student_id
              AND l.semester = :semester
              AND l.jenis_rapor = :jenis_rapor;
        """)
        res_lines = await self.db.execute(query_subjects, {
            "student_id": student_id,
            "semester": report_dict.get("semester"),
            "jenis_rapor": report_dict.get("jenis_rapor")
        })
        report_dict['subjects'] = [dict(row) for row in res_lines.mappings().all()]
        return report_dict

    async def get_rapor_attachment(self, rapor_id: int, student_id: int):
        level = await self.get_student_level_from_course(student_id)
        if level == 'sd':
            header_table, line_table, res_model = "ledger_rapor_sd", "ledger_rapor_sd_lm1", "ledger.rapor.sd"
        elif level == 'smp':
            header_table, line_table, res_model = "ledger_rapor_smp", "ledger_rapor_smp_lm1", "ledger.rapor.smp"
        elif level == 'tk':
            header_table, line_table, res_model = "ledger_rapor_tk", "ledger_rapor_tk_lm1", "ledger.rapor.tk"
        else:
            return None

        fk_col = f"{header_table}_id"

        query = text(f"""
            SELECT
                att.id,
                att.name AS file_name,
                att.mimetype,
                att.store_fname,
                att.db_datas
            FROM {line_table} l
            JOIN {header_table} h ON h.id = l.{fk_col}
            JOIN ir_attachment att ON (
                att.id = h.message_main_attachment_id
                OR (att.res_model = :res_model AND att.res_id = h.id)
            )
            WHERE l.id = :rapor_id
              AND l.student_id = :student_id
            ORDER BY att.id DESC
            LIMIT 1;
        """)
        result = await self.db.execute(query, {
            "rapor_id": rapor_id,
            "student_id": student_id,
            "res_model": res_model
        })
        return result.mappings().first()