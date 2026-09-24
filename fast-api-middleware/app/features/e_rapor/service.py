import sys
import os
import subprocess
import tempfile
from typing import Any, Dict, List, Optional, Tuple
from docxtpl import DocxTemplate
from app.features.e_rapor.repository import ERaporRepository

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

    def get_student_reports(
        self, uid: int, password: str, student_id: int, jenjang: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """Mengambil daftar e-rapor siswa per semester"""
        raw_reports = self.repo.get_student_reports(uid, password, student_id, jenjang=jenjang)
        results = []
        for report in raw_reports:
            header = report.get("header_data", {})
            kelas_name = self._extract_name(header.get("course_id"))
            tahun_name = self._extract_name(header.get("academic_year_id"))

            results.append({
                "id": report.get("id"),
                "student_id": student_id,
                "student_name": self._clean_value(self._extract_name(report.get("student_id"))),
                "kelas": self._clean_value(kelas_name),
                "semester": self._clean_value(report.get("semester")),
                "tahun_ajaran": self._clean_value(tahun_name),
                "rata_rata_nilai": float(report.get("nilai_rata_rata") or 0.0),
                "catatan_wali_kelas": self._clean_value(report.get("ct_kompetensi")),
                "status_keputusan": "",
                "file_rapor_pdf": f"/e-rapor/pdf/{report.get('id')}",
                "file_name": f"Rapor_Semester_{report.get('semester')}.pdf",
            })
        return results

    def get_report_detail(
        self, uid: int, password: str, rapor_id: int, student_id: int, jenjang: Optional[str] = None
    ) -> Dict[str, Any]:
        report = self.repo.get_report_card_details(
            uid, password, rapor_id, student_id, jenjang=jenjang
        ) or {}

        header = report.get("header_data", {})
        kelas_name = self._extract_name(header.get("course_id"))
        tahun_ajaran = self._extract_name(header.get("academic_year_id"))
        raw_subjects = report.get("subjects", [])

        subjects = []
        muatan_lokal = []

        idx_main = 1
        idx_lokal = 1

        for line in raw_subjects:
            subj_name = self._clean_value(self._extract_name(line.get("subject_id")))
            nilai_akhir = float(line.get("sts") or line.get("total_nilai") or 0.0)
            predikat = self._clean_value(line.get("cp_kompetensi"))
            catatan = self._clean_value(line.get("ct_kompetensi"))

            if not catatan and predikat:
                catatan = f"Menunjukkan penguasaan materi yang {predikat.lower()}"

            item = {
                "subject_name": subj_name,
                "nilai_akhir": f"{nilai_akhir:.0f}" if nilai_akhir > 0 else "",
                "predikat": predikat,
                "catatan": catatan,
            }

            # Pemisahan Muatan Pembelajaran & Muatan Lokal
            if any(key in subj_name.lower() for key in ["sunda", "lokal", "lingkungan"]):
                item["no"] = idx_lokal
                muatan_lokal.append(item)
                idx_lokal += 1
            else:
                item["no"] = idx_main
                subjects.append(item)
                idx_main += 1

        # Ambil data siswa dari repository secara aman (menggunakan self.repo)
        student = {}
        if hasattr(self.repo, "get_student_by_id"):
            student = self.repo.get_student_by_id(uid, password, student_id) or {}

        # Ambil data NIS & NISN dari objek report atau student
        nis = self._clean_value(report.get("nis") or student.get("nis"))
        nisn = self._clean_value(report.get("nisn") or student.get("nisn"))
        
        # Gabungkan NIS/NISN secara dinamis jika ada
        nis_nisn_val = f"{nis} / {nisn}".strip(" /") if (nis or nisn) else ""

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
            "kelas": self._clean_value(kelas_name),
            "fase": self._clean_value(report.get("fase") or header.get("fase")),
            "tahun_ajaran": self._clean_value(tahun_ajaran),
            "semester": self._clean_value(report.get("semester")),
            "subjects": subjects,
            "muatan_lokal": muatan_lokal,
            "tanggal_pengesahan": self._clean_value(header.get("write_date")),
            "wali_kelas": self._clean_value(self._extract_name(report.get("wali_kelas") or header.get("user_id"))),
        }

    def get_rapor_pdf_bytes(
        self, uid: int, password: str, rapor_id: int, student_id: int
    ) -> Optional[Tuple[bytes, str]]:
        detail = self.get_report_detail(uid, password, rapor_id, student_id)
        
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