import base64
import logging
from datetime import datetime, timedelta, timezone
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

LEGACY_RAPOR_MODEL_MAP = {
    'sd': {
        'report_model': 'raport.siswa.sts',
        'line_model': 'raport.siswa.line',
        'mulok_model': 'raport.siswa.mulok',
    },
    'smp': {
        'report_model': 'raport.siswa.sts.smp',
        'line_model': 'raport.siswa.line.smp',
        'mulok_model': 'raport.siswa.mulok.smp',
    },
    'tk': {
        'report_model': 'raport.siswa.sts.tk',
        'line_model': 'raport.siswa.line.tk',
        'mulok_model': 'raport.siswa.mulok.tk',
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

    def get_selection_labels(
        self, uid: int, password: str, model: str, field_name: str
    ) -> Dict[str, str]:
        """Return Odoo selection keys mapped to their translated display labels."""
        try:
            metadata = self.odoo.execute_kw(
                uid,
                password,
                model,
                "fields_get",
                [],
                {"attributes": ["selection"]},
            )
        except Exception as exc:
            logger.warning(
                "[e-rapor repo] Gagal membaca selection %s.%s: %s",
                model,
                field_name,
                exc,
            )
            return {}

        field_metadata = metadata.get(field_name) if isinstance(metadata, dict) else None
        selection = field_metadata.get("selection") if isinstance(field_metadata, dict) else None
        if not isinstance(selection, (list, tuple)):
            return {}
        return {
            str(option[0]): str(option[1])
            for option in selection
            if isinstance(option, (list, tuple)) and len(option) >= 2
        }

    def _legacy_config(self, jenjang: Optional[str]) -> Dict[str, str]:
        return LEGACY_RAPOR_MODEL_MAP.get(
            (jenjang or 'sd').lower(), LEGACY_RAPOR_MODEL_MAP['sd']
        )

    def _get_model_metadata(
        self, uid: int, password: str, model: str
    ) -> Dict[str, Any]:
        metadata = self.odoo.execute_kw(
            uid,
            password,
            model,
            "fields_get",
            [],
            {"attributes": ["type", "selection", "relation", "relation_field"]},
        )
        if not isinstance(metadata, dict):
            raise RuntimeError(f"Odoo tidak mengembalikan metadata model {model}.")
        return metadata

    def _search_all(
        self,
        uid: int,
        password: str,
        model: str,
        domain: List[Any],
        fields: List[str],
        order: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        records: List[Dict[str, Any]] = []
        offset = 0
        page_size = 80
        while True:
            page = self.odoo.search_read(
                uid=uid,
                password=password,
                model=model,
                domain=domain,
                fields=fields,
                limit=page_size,
                offset=offset,
                order=order,
            )
            records.extend(page)
            if len(page) < page_size:
                return records
            offset += len(page)

    @staticmethod
    def _first_existing_field(
        metadata: Dict[str, Any], candidates: Tuple[str, ...]
    ) -> Optional[str]:
        return next((field for field in candidates if field in metadata), None)

    @staticmethod
    def _selection_labels(
        metadata: Dict[str, Any], field_name: Optional[str]
    ) -> Dict[str, str]:
        if not field_name:
            return {}
        field = metadata.get(field_name)
        selection = field.get("selection") if isinstance(field, dict) else None
        if not isinstance(selection, (list, tuple)):
            return {}
        return {
            str(option[0]): str(option[1])
            for option in selection
            if isinstance(option, (list, tuple)) and len(option) >= 2
        }

    @staticmethod
    def _extract_id(value: Any) -> Optional[int]:
        if isinstance(value, (list, tuple)) and value and isinstance(value[0], int):
            return value[0]
        if isinstance(value, int):
            return value
        return None

    @staticmethod
    def _label_selection(
        value: Any, labels: Dict[str, str]
    ) -> Any:
        if isinstance(value, (list, tuple)) and value:
            key = value[0]
        else:
            key = value
        return labels.get(str(key), value)

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

    def _get_ledger_report_card_details(
        self,
        uid: int,
        password: str,
        rapor_id: int,
        student_id: int,
        jenjang: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        """Legacy ledger-based reader retained for compatibility with old data."""
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

    def get_course_phase(
        self, uid: int, password: str, course_id: int
    ) -> Optional[Any]:
        """Ambil fase dari record kelas bila field tersebut tersedia di Odoo."""
        try:
            available_fields = self.odoo.execute_kw(
                uid,
                password,
                "op.course",
                "fields_get",
                [],
                {"attributes": ["type"]},
            )
            if not isinstance(available_fields, dict):
                return None

            phase_field = next(
                (
                    field
                    for field in ("fase", "phase", "fase_id", "phase_id")
                    if field in available_fields
                ),
                None,
            )
            if not phase_field:
                return None

            courses = self.odoo.search_read(
                uid=uid,
                password=password,
                model="op.course",
                domain=[("id", "=", course_id)],
                fields=[phase_field],
                limit=1,
            )
            return courses[0].get(phase_field) if courses else None
        except Exception as exc:
            logger.warning(
                "[e-rapor repo] Gagal mengambil fase kelas course_id=%s: %s",
                course_id,
                exc,
            )
            return None
    
    def resolve_student_id(
        self,
        uid: int,
        password: str,
        partner_id: Optional[int] = None,
    ) -> Optional[int]:
        """Resolve the authenticated Odoo user to an op.student record."""
        student_fields = self.odoo.execute_kw(
            uid,
            password,
            "op.student",
            "fields_get",
            [],
            {"attributes": ["type"]},
        )
        if not isinstance(student_fields, dict):
            raise RuntimeError("Odoo tidak mengembalikan metadata field op.student.")

        if "user_id" in student_fields:
            students = self.odoo.search_read(
                uid,
                password,
                "op.student",
                [("user_id", "=", uid)],
                ["id"],
                1,
            )
            if students and isinstance(students[0].get("id"), int):
                return students[0]["id"]

        if partner_id and "partner_id" in student_fields:
            students = self.odoo.search_read(
                uid,
                password,
                "op.student",
                [("partner_id", "=", partner_id)],
                ["id"],
                2,
            )
            if len(students) == 1 and isinstance(students[0].get("id"), int):
                return students[0]["id"]

        user_fields = self.odoo.execute_kw(
            uid,
            password,
            "res.users",
            "fields_get",
            [],
            {"attributes": ["type"]},
        )
        if not isinstance(user_fields, dict):
            raise RuntimeError("Odoo tidak mengembalikan metadata field res.users.")

        relation_fields = [
            field for field in ("student_line", "student_id")
            if field in user_fields
        ]
        if not relation_fields:
            return None

        users = self.odoo.search_read(
            uid,
            password,
            "res.users",
            [("id", "=", uid)],
            relation_fields,
            1,
        )
        if not users:
            return None

        for field in relation_fields:
            value = users[0].get(field)
            if isinstance(value, (list, tuple)) and value and isinstance(value[0], int):
                value = value[0]
            if isinstance(value, int) and value > 0:
                return value
        return None
    def get_student_reports(
        self,
        uid: int,
        password: str,
        student_id: int,
        jenjang: Optional[str] = None,
        report_ids: Optional[List[int]] = None,
    ) -> List[Dict[str, Any]]:
        cfg = self._legacy_config(jenjang)
        model = cfg["report_model"]
        metadata = self._get_model_metadata(uid, password, model)
        student_field = self._first_existing_field(metadata, ("student_id",))
        if not student_field:
            raise RuntimeError(f"Model {model} tidak memiliki field student_id.")

        fields = [
            field
            for field in (
                "id",
                "write_date",
                student_field,
                "kelas_id",
                "grade_id",
                "tahun_pelajaran",
                "semester_id",
                "jenis_raport",
                "fase",
                "active",
                "walas",
                "nama_sekolah",
                "alamat_sekolah",
                "tanggal_rapor",
                "keputusan_siswa",
                "raport_siswa_ids",
            )
            if field in metadata
        ]
        domain = [(student_field, "=", student_id)]
        if report_ids is not None:
            if not report_ids:
                return []
            domain.append(("id", "in", report_ids))
        if "active" in metadata:
            domain.append(("active", "=", True))

        reports = self._search_all(
            uid, password, model, domain, fields, order="id desc"
        )
        semester_field = self._first_existing_field(metadata, ("semester_id",))
        type_field = self._first_existing_field(metadata, ("jenis_raport",))
        phase_field = self._first_existing_field(metadata, ("fase",))
        semester_labels = self._selection_labels(metadata, semester_field)
        type_labels = self._selection_labels(metadata, type_field)
        phase_labels = self._selection_labels(metadata, phase_field)

        for report in reports:
            report["semester_label"] = self._label_selection(
                report.get(semester_field) if semester_field else None,
                semester_labels,
            )
            report["jenis_rapor_label"] = self._label_selection(
                report.get(type_field) if type_field else None,
                type_labels,
            )
            report["fase_label"] = self._label_selection(
                report.get(phase_field) if phase_field else None,
                phase_labels,
            )
            report["header_data"] = {
                "course_id": report.get("kelas_id"),
                "academic_year_id": report.get("tahun_pelajaran"),
                "write_date": report.get("write_date"),
                "user_id": report.get("walas"),
            }
        return reports

    def get_student_reports_sync(
        self,
        uid: int,
        password: str,
        student_id: int,
        jenjang: Optional[str],
        cursor: Optional[str],
    ) -> Dict[str, Any]:
        started_at = datetime.now(timezone.utc)
        watermark = started_at.strftime("%Y-%m-%d %H:%M:%S")
        cfg = self._legacy_config(jenjang)
        report_model = cfg["report_model"]
        report_metadata = self._get_model_metadata(uid, password, report_model)
        if "write_date" not in report_metadata:
            raise RuntimeError(
                f"Model {report_model} tidak menyediakan write_date; "
                "sinkronisasi cursor e-Rapor tidak aman."
            )

        if cursor is None:
            return {
                "items": self.get_student_reports(
                    uid, password, student_id, jenjang=jenjang
                ),
                "removed_ids": [],
                "next_cursor": watermark,
                "full_sync": True,
            }

        try:
            parsed_cursor = datetime.fromisoformat(cursor.replace("Z", "+00:00"))
            if parsed_cursor.tzinfo is None:
                parsed_cursor = parsed_cursor.replace(tzinfo=timezone.utc)
            since = (parsed_cursor - timedelta(minutes=2)).astimezone(
                timezone.utc
            ).strftime("%Y-%m-%d %H:%M:%S")
        except ValueError as exc:
            raise ValueError("Cursor e-Rapor tidak valid.") from exc

        student_field = self._first_existing_field(
            report_metadata, ("student_id",)
        )
        if not student_field:
            raise RuntimeError(
                f"Model {report_model} tidak memiliki field student_id."
            )
        changed_headers = self._search_all(
            uid,
            password,
            report_model,
            [
                (student_field, "=", student_id),
                ("write_date", ">=", since),
            ],
            ["id"],
        )
        candidate_ids = {row["id"] for row in changed_headers}

        child_relations = []
        for relation_field in ("raport_siswa_ids", "mulok_siswa_ids"):
            relation_info = report_metadata.get(relation_field)
            child_model = (
                relation_info.get("relation")
                if isinstance(relation_info, dict)
                and relation_info.get("type") == "one2many"
                else None
            )
            if child_model:
                child_metadata = self._get_model_metadata(
                    uid, password, child_model
                )
                if "write_date" not in child_metadata:
                    raise RuntimeError(
                        f"Model terkait {child_model} tidak menyediakan "
                        "write_date; sinkronisasi cursor e-Rapor tidak aman."
                    )
                parent_field = relation_info.get("relation_field")
                if not parent_field or parent_field not in child_metadata:
                    raise RuntimeError(
                        f"Relasi {report_model}.{relation_field} ke parent "
                        "tidak dapat diverifikasi."
                    )
                child_relations.append((child_model, parent_field))

        for child_model, parent_field in child_relations:
            changed_children = self._search_all(
                uid,
                password,
                child_model,
                [("write_date", ">=", since)],
                ["id", parent_field],
            )
            candidate_ids.update(
                parent_id
                for row in changed_children
                if (
                    parent_id := self._extract_id(row.get(parent_field))
                ) is not None
            )

        if not candidate_ids:
            return {
                "items": [],
                "removed_ids": [],
                "next_cursor": watermark,
                "full_sync": False,
            }

        current_reports = self.get_student_reports(
            uid,
            password,
            student_id,
            jenjang=jenjang,
            report_ids=sorted(candidate_ids),
        )
        current_ids = {row["id"] for row in current_reports}
        return {
            "items": current_reports,
            "removed_ids": sorted(candidate_ids - current_ids),
            "next_cursor": watermark,
            "full_sync": False,
        }

    def get_report_card_details(
        self,
        uid: int,
        password: str,
        rapor_id: int,
        student_id: int,
        jenjang: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        """Ambil satu laporan STS dan detailnya melalui relasi model raport.siswa."""
        cfg = self._legacy_config(jenjang)
        report_model = cfg["report_model"]
        report_metadata = self._get_model_metadata(uid, password, report_model)
        student_field = self._first_existing_field(report_metadata, ("student_id",))
        if not student_field:
            raise RuntimeError(
                f"Model {report_model} tidak memiliki field student_id."
            )

        report_fields = [
            field
            for field in (
                "id",
                student_field,
                "kelas_id",
                "grade_id",
                "tahun_pelajaran",
                "semester_id",
                "jenis_raport",
                "fase",
                "nama_sekolah",
                "alamat_sekolah",
                "tanggal_rapor",
                "walas",
                "kepsek",
                "ortu",
                "keputusan_siswa",
                "state",
                "raport_siswa_ids",
                "mulok_siswa_ids",
                "kegiatan_siswa_ids",
                "prestasi_siswa_ids",
            )
            if field in report_metadata
        ]
        domain = [("id", "=", rapor_id), (student_field, "=", student_id)]
        if "active" in report_metadata:
            domain.append(("active", "=", True))
        reports = self.odoo.search_read(
            uid=uid,
            password=password,
            model=report_model,
            domain=domain,
            fields=report_fields,
            limit=1,
        )
        if not reports:
            return None

        report = reports[0]
        subject_lines = self._get_legacy_report_lines(
            uid,
            password,
            cfg["line_model"],
            rapor_id,
        )
        mulok_lines = self._get_legacy_report_lines(
            uid,
            password,
            cfg["mulok_model"],
            rapor_id,
        )

        semester_field = self._first_existing_field(
            report_metadata, ("semester_id",)
        )
        type_field = self._first_existing_field(report_metadata, ("jenis_raport",))
        phase_field = self._first_existing_field(report_metadata, ("fase",))
        report["semester"] = self._label_selection(
            report.get(semester_field) if semester_field else None,
            self._selection_labels(report_metadata, semester_field),
        )
        report["jenis_rapor"] = self._label_selection(
            report.get(type_field) if type_field else None,
            self._selection_labels(report_metadata, type_field),
        )
        report["fase"] = self._label_selection(
            report.get(phase_field) if phase_field else None,
            self._selection_labels(report_metadata, phase_field),
        )
        report["header_data"] = {
            "course_id": report.get("kelas_id"),
            "academic_year_id": report.get("tahun_pelajaran"),
            "write_date": report.get("tanggal_rapor"),
            "user_id": report.get("walas"),
            "nama_sekolah": report.get("nama_sekolah"),
            "alamat_sekolah": report.get("alamat_sekolah"),
        }
        report["subjects"] = subject_lines
        report["muatan_lokal"] = mulok_lines
        return report

    def _get_legacy_report_lines(
        self, uid: int, password: str, model: str, rapor_id: int
    ) -> List[Dict[str, Any]]:
        metadata = self._get_model_metadata(uid, password, model)
        report_field = self._first_existing_field(metadata, ("raport_id",))
        if not report_field:
            raise RuntimeError(f"Model {model} tidak memiliki field raport_id.")

        fields = [
            field
            for field in ("id", "subject_id", "nilai_akhir", "note", "note2")
            if field in metadata
        ]
        lines = self.odoo.search_read(
            uid=uid,
            password=password,
            model=model,
            domain=[(report_field, "=", rapor_id)],
            fields=fields,
            limit=500,
            order="id asc",
        )
        return lines

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