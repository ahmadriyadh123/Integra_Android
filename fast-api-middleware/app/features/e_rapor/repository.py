import base64
import logging
from typing import List, Dict, Any, Optional, Tuple
from app.core.odoo_client import OdooRPCClient

logger = logging.getLogger(__name__)

# Pemetaan model Odoo sesuai skema database terbaru
JENJANG_MODEL_MAP = {
    'sd': {
        'header_model': 'ledger.rapor.sd',
        'line_model': 'ledger.rapor.sd.lm1',
        'line_fk': 'ledger_rapor_sd_id',
    },
    'smp': {
        'header_model': 'ledger.rapor.smp',
        'line_model': 'ledger.rapor.smp.lm1',
        'line_fk': 'ledger_rapor_smp_id',
    },
    'tk': {
        'header_model': 'ledger.rapor.tk',
        'line_model': 'ledger.rapor.tk.lm1',
        'line_fk': 'ledger_rapor_tk_id',
    },
}

HEADER_FIELDS = [
    'id',
    'course_id',
    'academic_year_id',
    'subject_id',
    'student_id',
    'message_main_attachment_id',
]

LINE_FIELDS = [
    'id',
    'student_id',
    'semester',
    'jenis_rapor',
    'nilai_rata_rata',
    'ct_kompetensi',
    'cp_kompetensi',
    'sts',
    'total_nilai',
]

class ERaporRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def _get_config(self, jenjang: Optional[str]) -> dict:
        key = (jenjang or 'sd').lower()
        return JENJANG_MODEL_MAP.get(key, JENJANG_MODEL_MAP['sd'])

    def _configs_to_try(self, jenjang: Optional[str]) -> List[dict]:
        primary = self._get_config(jenjang)
        return [primary] + [
            config for config in JENJANG_MODEL_MAP.values() if config is not primary
        ]

    def get_student_level_from_course(self, uid: int, password: str, student_id: int) -> Optional[str]:
        """Auto-detect jenjang sekolah tanpa melempar error jika terhalang hak akses"""
        try:
            student = self.odoo.search_read(
                uid=uid,
                password=password,
                model='op.student',
                domain=[('id', '=', student_id)],
                fields=['name'],  # Hindari course_detail_ids yang terhalang Access Rights
                limit=1
            )
            if student:
                name = str(student[0].get('name', '')).lower()
                if 'smp' in name:
                    return 'smp'
                if 'tk' in name or 'paud' in name or 'kb' in name:
                    return 'tk'
                if 'sd' in name:
                    return 'sd'
        except Exception as e:
            logger.warning("[e-rapor repo] Terhalang hak akses auto-detect level: %s", e)
        return 'sd'  # Fallback default

    def get_report_card_details(
        self,
        uid: int,
        password: str,
        rapor_id: int,
        student_id: int,
        jenjang: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        """Mengambil detail e-rapor. Jika terhalang hak akses, tetap mengembalikan struktur dasar."""
        if not jenjang:
            jenjang = self.get_student_level_from_course(uid, password, student_id)
        cfg = self._get_config(jenjang)
        line_model = cfg['line_model']
        header_model = cfg['header_model']
        line_fk = cfg['line_fk']

        report_data = {
            "id": rapor_id,
            "student_id": student_id,
            "semester": "-",
            "jenis_rapor": "-",
            "header_data": {},
            "subjects": []
        }

        # 1. Ambil target line rapor
        try:
            target_line = self.odoo.search_read(
                uid=uid,
                password=password,
                model=line_model,
                domain=[('id', '=', rapor_id)],
                fields=LINE_FIELDS + [line_fk],
                limit=1
            )
            if target_line:
                report_data.update(target_line[0])
        except Exception as e:
            logger.warning("[e-rapor repo] Akses ditolak untuk target line %s: %s", line_model, e)

        semester = report_data.get('semester')
        jenis_rapor = report_data.get('jenis_rapor')

        # 2. Ambil header info
        h_id = report_data.get(line_fk)
        if isinstance(h_id, (list, tuple)) and len(h_id) > 0:
            h_id = h_id[0]

        if h_id:
            try:
                headers = self.odoo.search_read(
                    uid=uid,
                    password=password,
                    model=header_model,
                    domain=[('id', '=', h_id)],
                    fields=HEADER_FIELDS,
                    limit=1
                )
                if headers:
                    report_data['header_data'] = headers[0]
            except Exception as e:
                logger.warning("[e-rapor repo] Akses ditolak untuk header %s: %s", header_model, e)

        # 3. Ambil seluruh mata pelajaran
        try:
            all_lines = self.odoo.search_read(
                uid=uid,
                password=password,
                model=line_model,
                domain=[
                    ('student_id', '=', student_id),
                    ('semester', '=', semester),
                    ('jenis_rapor', '=', jenis_rapor)
                ],
                fields=LINE_FIELDS + [line_fk]
            )

            all_h_ids = list({l[line_fk][0] for l in all_lines if l.get(line_fk) and isinstance(l.get(line_fk), (list, tuple))})
            sub_header_dict = {}
            if all_h_ids:
                try:
                    all_headers = self.odoo.search_read(
                        uid=uid,
                        password=password,
                        model=header_model,
                        domain=[('id', 'in', all_h_ids)],
                        fields=['id', 'subject_id']
                    )
                    sub_header_dict = {h['id']: h.get('subject_id') for h in all_headers}
                except Exception as e:
                    logger.warning("[e-rapor repo] Akses ditolak untuk subject headers: %s", e)

            for line in all_lines:
                fk_val = line[line_fk][0] if isinstance(line.get(line_fk), (list, tuple)) else line.get(line_fk)
                line['subject_id'] = sub_header_dict.get(fk_val)
            
            report_data['subjects'] = all_lines
        except Exception as e:
            logger.warning("[e-rapor repo] Akses ditolak untuk subjects %s: %s", line_model, e)

        return report_data

    def get_student_id_by_uid(self, uid: int, password: str) -> Optional[int]:
        """Resolusi pencarian ID op.student dari res_users UID"""
        try:
            students = self.odoo.search_read(
                uid=uid,
                password=password,
                model="op.student",
                domain=[("user_id", "=", uid)],
                fields=["id"],
                limit=1
            )
            if students:
                return students[0]["id"]
        except Exception as e:
            logger.warning(f"Gagal mencari op.student dari user_id {uid}: {e}")
        return None
    
    def get_student_reports(
        self, uid: int, password: str, student_id: int, jenjang: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        # 1. Pastikan student_id benar-benar ID dari op.student (121), bukan UID (17)
        resolved_student_id = self.get_student_id_by_uid(uid, password) or student_id

        # Ikuti jenjang dari token seperti endpoint Weekly Plan, lalu fallback
        # ke model jenjang lain bila data belum ditemukan.
        for cfg in self._configs_to_try(jenjang):
            line_model = cfg['line_model']
            header_model = cfg['header_model']
            line_fk = cfg['line_fk']

            try:
                lines = self.odoo.search_read(
                    uid=uid,
                    password=password,
                    model=line_model,
                    domain=[('student_id', '=', resolved_student_id)],
                    fields=LINE_FIELDS + [line_fk],
                    order='id desc'
                )

                if not lines:
                    continue

                # Ambil data header terkait
                header_ids = list({
                    l[line_fk][0] if isinstance(l.get(line_fk), (list, tuple)) else l.get(line_fk)
                    for l in lines if l.get(line_fk)
                })

                headers = self.odoo.search_read(
                    uid=uid,
                    password=password,
                    model=header_model,
                    domain=[('id', 'in', header_ids)],
                    fields=HEADER_FIELDS
                )
                header_dict = {h['id']: h for h in headers}

                for line in lines:
                    fk_val = line.get(line_fk)
                    h_id = fk_val[0] if isinstance(fk_val, (list, tuple)) else fk_val
                    line['header_data'] = header_dict.get(h_id, {})

                return lines

            except Exception as e:
                logger.warning(f"Pencarian pada model {line_model} gagal: {e}")

        return []

    def get_report_card_details(
        self,
        uid: int,
        password: str,
        rapor_id: int,
        student_id: int,
        jenjang: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        """Mengambil detail e-rapor beserta nilai seluruh mata pelajaran semester terkait"""
        if not jenjang:
            jenjang = self.get_student_level_from_course(uid, password, student_id)

        cfg = self._get_config(jenjang)
        line_model = cfg['line_model']
        header_model = cfg['header_model']
        line_fk = cfg['line_fk']

        try:
            # 1. Ambil target line rapor
            target_line = self.odoo.search_read(
                uid=uid,
                password=password,
                model=line_model,
                domain=[('id', '=', rapor_id), ('student_id', '=', student_id)],
                fields=LINE_FIELDS + [line_fk],
                limit=1
            )
            if not target_line:
                return None

            report_data = target_line[0]
            semester = report_data.get('semester')
            jenis_rapor = report_data.get('jenis_rapor')

            # 2. Ambil header info
            h_id = report_data[line_fk][0] if report_data.get(line_fk) else None
            if h_id:
                headers = self.odoo.search_read(
                    uid=uid,
                    password=password,
                    model=header_model,
                    domain=[('id', '=', h_id)],
                    fields=HEADER_FIELDS,
                    limit=1
                )
                report_data['header_data'] = headers[0] if headers else {}

            # 3. Ambil seluruh mata pelajaran pada semester dan jenis rapor yang sama
            all_lines = self.odoo.search_read(
                uid=uid,
                password=password,
                model=line_model,
                domain=[
                    ('student_id', '=', student_id),
                    ('semester', '=', semester),
                    ('jenis_rapor', '=', jenis_rapor)
                ],
                fields=LINE_FIELDS + [line_fk]
            )

            # Map subject name dari header masing-masing line
            all_h_ids = list({l[line_fk][0] for l in all_lines if l.get(line_fk)})
            all_headers = self.odoo.search_read(
                uid=uid,
                password=password,
                model=header_model,
                domain=[('id', 'in', all_h_ids)],
                fields=['id', 'subject_id']
            )
            sub_header_dict = {h['id']: h.get('subject_id') for h in all_headers}

            for line in all_lines:
                fk_val = line[line_fk][0] if line.get(line_fk) else None
                line['subject_id'] = sub_header_dict.get(fk_val)

            report_data['subjects'] = all_lines
            return report_data
        except Exception as e:
            logger.warning("[e-rapor repo] Gagal mengambil detail rapor ID %s: %s", rapor_id, e)
            return None

    def get_rapor_attachment(
        self, uid: int, password: str, rapor_id: int, student_id: int
    ) -> Optional[Tuple[bytes, str]]:
        """Mengambil lampiran PDF dari ir.attachment berdasarkan res_model dan res_id"""
        models = [cfg['header_model'] for cfg in JENJANG_MODEL_MAP.values()]
        try:
            attachments = self.odoo.search_read(
                uid=uid,
                password=password,
                model='ir.attachment',
                domain=[('res_model', 'in', models), ('res_id', '=', rapor_id)],
                fields=['id', 'name', 'datas'],
                limit=1
            )
            if attachments and attachments[0].get('datas'):
                raw_b64 = attachments[0]['datas']
                name = attachments[0].get('name') or f"e-rapor-{rapor_id}.pdf"
                pdf_bytes = base64.b64decode(raw_b64)
                return pdf_bytes, name
        except Exception as e:
            logger.warning("[e-rapor repo] Gagal membaca lampiran PDF rapor_id=%s: %s", rapor_id, e)
        return None