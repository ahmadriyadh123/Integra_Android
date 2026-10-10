import sys
import os
import subprocess
import tempfile
from typing import Any, Dict, List, Optional, Tuple
from docxtpl import DocxTemplate
from app.features.e_rapor.repository import ERaporRepository
from app.features.profile.repository import ProfileRepository

class ERaporService:
    def __init__(self, repo: ERaporRepository):
        self.repo = repo
        self.template_path = os.path.join(
            os.path.dirname(__file__), "templates", "rapor_template.docx"
        )

    @staticmethod
    def _text(value: Any, fallback: str = "") -> str:
        return str(value) if value is not None and value is not False and value != "" else fallback

    @staticmethod
    def _extract_name(value: Any) -> Optional[str]:
        if isinstance(value, (list, tuple)) and len(value) >= 2:
            return str(value[1])
        if value is not None and value is not False:
            return str(value)
        return None

    @staticmethod
    def _extract_id(value: Any) -> Optional[int]:
        if isinstance(value, (list, tuple)) and len(value) >= 1:
            return value[0] if isinstance(value[0], int) else None
        if isinstance(value, int):
            return value
        return None

    @staticmethod
    def _get_libreoffice_cmd() -> str:
        """Mencari path eksekusi LibreOffice secara presisi di Windows / Linux."""
        if sys.platform.startswith("win"):
            possible_paths = [
                r"C:\Program Files\LibreOffice\program\soffice.exe",
                r"C:\Program Files (x86)\LibreOffice\program\soffice.exe",
                "soffice",
            ]
            for path in possible_paths:
                if os.path.exists(path):
                    return path
            return "soffice"
        return "libreoffice"

    def _clean_value(self, val: Any) -> Any:
        """
        Mengembalikan nilai asli jika valid, atau string kosong jika None/False/empty string.
        Memastikan tidak ada default fallback berupa '-'.
        """
        if val is None or val is False:
            return ""
        return val

    @staticmethod
    def _display_report_type(value: Any) -> str:
        if value is None or value is False:
            return ""
        text = str(value).strip()
        aliases = {
            "sts": "Sumatif Tengah Semester",
            "sumatif_tengah_semester": "Sumatif Tengah Semester",
            "sas": "Sumatif Akhir Semester",
            "sumatif_akhir_semester": "Sumatif Akhir Semester",
            "sat": "Sumatif Akhir Tahun",
            "sumatif_akhir_tahun": "Sumatif Akhir Tahun",
        }
        return aliases.get(text.lower(), text)

    @staticmethod
    def _display_semester(value: Any) -> str:
        if value is None or value is False:
            return ""
        text = str(value).strip()
        aliases = {
            "1": "Gasal",
            "semester 1": "Gasal",
            "2": "Genap",
            "semester 2": "Genap",
        }
        return aliases.get(text.lower(), text)

    def get_student_reports(
        self,
        uid: int,
        password: str,
        student_id: int,
        jenjang: Optional[str] = None,
        report_ids: Optional[List[int]] = None,
    ) -> List[Dict[str, Any]]:
        """Mengambil daftar e-rapor siswa per semester"""
        if report_ids is None:
            raw_reports = self.repo.get_student_reports(
                uid, password, student_id, jenjang=jenjang
            )
        else:
            raw_reports = self.repo.get_student_reports(
                uid,
                password,
                student_id,
                jenjang=jenjang,
                report_ids=report_ids,
            )
        return self._map_student_reports(raw_reports, student_id)

    def sync_student_reports(
        self,
        uid: int,
        password: str,
        student_id: int,
        jenjang: Optional[str],
        cursor: Optional[str],
    ) -> Dict[str, Any]:
        sync = self.repo.get_student_reports_sync(
            uid, password, student_id, jenjang, cursor
        )
        sync["items"] = self._map_student_reports(sync["items"], student_id)
        return sync

    def _map_student_reports(
        self, raw_reports: List[Dict[str, Any]], student_id: int
    ) -> List[Dict[str, Any]]:
        results = []
        for report in raw_reports:
            header = report.get("header_data", {})
            kelas_name = self._extract_name(header.get("course_id"))
            tahun_name = self._extract_name(header.get("academic_year_id"))
            semester = report.get("semester_label") or report.get("semester")

            results.append({
                "id": report.get("id"),
                "student_id": student_id,
                "student_name": self._clean_value(self._extract_name(report.get("student_id"))),
                "jenis_rapor": self._display_report_type(
                    report.get("jenis_rapor_label") or report.get("jenis_rapor")
                ),
                "kelas": self._clean_value(kelas_name),
                "semester": self._display_semester(
                    semester
                ),
                "tahun_ajaran": self._clean_value(tahun_name),
                "rata_rata_nilai": float(report.get("nilai_rata_rata") or 0.0),
                "catatan_wali_kelas": self._clean_value(report.get("ct_kompetensi")),
                "status_keputusan": "",
                "file_rapor_pdf": f"/e-rapor/pdf/{report.get('id')}",
                "file_name": f"Rapor_Semester_{semester or ''}.pdf",
            })
        return results

    def get_report_detail(
        self, uid: int, password: str, rapor_id: int, student_id: int, jenjang: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        report = self.repo.get_report_card_details(
            uid, password, rapor_id, student_id, jenjang=jenjang
        )
        if not report:
            return None

        header = report.get("header_data", {})
        kelas_name = self._extract_name(header.get("course_id"))
        tahun_ajaran = self._extract_name(header.get("academic_year_id"))
        raw_subjects = report.get("subjects", [])

        def map_lines(lines: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
            mapped = []
            for index, line in enumerate(lines, start=1):
                score = line.get("nilai_akhir")
                if score in (None, False, ""):
                    score = line.get("sts") or line.get("total_nilai")
                try:
                    numeric_score = float(score or 0.0)
                except (TypeError, ValueError):
                    numeric_score = 0.0

                predikat = line.get("note") or line.get("cp_kompetensi")
                catatan = line.get("note2") or line.get("ct_kompetensi")
                if not catatan and predikat:
                    catatan = f"Menunjukkan penguasaan materi yang {str(predikat).lower()}"

                mapped.append({
                    "no": index,
                    "subject_name": self._clean_value(
                        self._extract_name(line.get("subject_id"))
                    ),
                    "nilai_akhir": (
                        f"{numeric_score:.0f}" if numeric_score > 0 else ""
                    ),
                    "predikat": self._clean_value(predikat),
                    "catatan": self._clean_value(catatan),
                })
            return mapped

        subjects = map_lines(raw_subjects)
        muatan_lokal = map_lines(report.get("muatan_lokal", []))
        if not muatan_lokal:
            muatan_lokal.append({
                "no": "",
                "subject_name": "",
                "nilai_akhir": "",
                "predikat": "",
                "catatan": "",
            })

        # Gunakan sumber data siswa yang sama dengan fitur Profil.
        student = ProfileRepository(self.repo.odoo).get_student_profile_record(
            uid=uid,
            password=password,
            student_id=student_id,
        ) or {}

        nis = self._clean_value(
            report.get("nis")
            or student.get("nis")
            or student.get("gr_no")
            or student.get("student_code")
        )
        nisn = self._clean_value(
            report.get("nisn") or student.get("nisn") or student.get("nisn_no")
        )
        
        # Gabungkan NIS/NISN secara dinamis jika ada
        nis_nisn_val = f"{nis} / {nisn}".strip(" /") if (nis or nisn) else ""

        student_kelas = (
            student.get("grade") or student.get("course_id") or student.get("class_id")
        )
        phase = (
            report.get("fase")
            or report.get("phase")
            or header.get("fase")
            or header.get("phase")
            or student.get("fase")
            or student.get("phase")
            or student.get("fase_id")
            or student.get("phase_id")
        )
        if not phase and hasattr(self.repo, "get_course_phase"):
            course_id = self._extract_id(header.get("course_id")) or self._extract_id(
                student_kelas
            )
            if course_id:
                phase = self.repo.get_course_phase(uid, password, course_id)

        # Ambil nama sekolah & alamat sekolah dari report / header / company
        nama_sekolah = report.get("nama_sekolah") or header.get("nama_sekolah") or header.get("company_id")
        alamat_sekolah = report.get("alamat_sekolah") or header.get("alamat_sekolah")

        return {
            "id": report.get("id", rapor_id),
            "nama_sekolah": self._clean_value(self._extract_name(nama_sekolah)),
            "alamat_sekolah": self._clean_value(alamat_sekolah),
            "student_id": student_id,
            "student_name": self._clean_value(
                report.get("student_name") or self._extract_name(report.get("student_id")) or student.get("name")
            ),
            "nis_nisn": nis_nisn_val,
            "kelas": self._clean_value(kelas_name or self._extract_name(student_kelas)),
            "fase": self._clean_value(self._extract_name(phase)),
            "tahun_ajaran": self._clean_value(tahun_ajaran),
            "semester": self._clean_value(report.get("semester")),
            "subjects": subjects,
            "muatan_lokal": muatan_lokal,
            "mulok": muatan_lokal,
            "tanggal_pengesahan": self._clean_value(header.get("write_date")),
            "wali_kelas": self._clean_value(self._extract_name(report.get("wali_kelas") or header.get("user_id"))),
        }

    def get_rapor_pdf_bytes(
        self,
        uid: int,
        password: str,
        rapor_id: int,
        student_id: int,
        jenjang: Optional[str] = None,
    ) -> Optional[Tuple[bytes, str]]:
        detail = self.get_report_detail(
            uid, password, rapor_id, student_id, jenjang=jenjang
        )
        if not detail:
            return None

        pdf_bytes = self.generate_pdf_from_template(detail)
        
        student_name_clean = str(detail['student_name']).replace(' ', '_').replace('/', '-') or f"Siswa_{student_id}"
        filename = f"E-Rapor_{student_name_clean}_ID{rapor_id}.pdf"
        
        return pdf_bytes, filename

    def generate_pdf_from_template(self, context_data: Dict[str, Any]) -> bytes:
        if not os.path.exists(self.template_path):
            raise FileNotFoundError(f"Template Word tidak ditemukan di: {self.template_path}")

        doc = DocxTemplate(self.template_path)
        doc.render(context_data)

        with tempfile.TemporaryDirectory() as temp_dir:
            temp_docx_path = os.path.join(temp_dir, "rapor_output.docx")
            doc.save(temp_docx_path)

            libreoffice_bin = self._get_libreoffice_cmd()
            cmd = [
                libreoffice_bin,
                "--headless",
                "--convert-to", "pdf",
                "--outdir", temp_dir,
                temp_docx_path
            ]

            use_shell = sys.platform.startswith("win")

            subprocess.run(
                cmd, 
                check=True, 
                stdout=subprocess.PIPE, 
                stderr=subprocess.PIPE,
                shell=use_shell
            )

            temp_pdf_path = os.path.join(temp_dir, "rapor_output.pdf")
            with open(temp_pdf_path, "rb") as f:
                return f.read()