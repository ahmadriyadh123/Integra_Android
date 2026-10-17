import asyncio
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from docxtpl import DocxTemplate

from app.features.e_rapor.repository import ERaporRepository


class ERaporService:
    def __init__(self, repo: ERaporRepository):
        self.repo = repo
        self.template_path = (
            Path(__file__).resolve().parent / "templates" / "rapor_template.docx"
        )

    @staticmethod
    def _localized(value: Any, fallback: str = "-") -> str:
        if isinstance(value, dict):
            value = value.get("en_US") or next(iter(value.values()), None)
        if value is None or value is False or value == "":
            return fallback
        return str(value).strip() or fallback

    @staticmethod
    def _semester_label(value: Any) -> str:
        normalized = str(value or "").strip().lower()
        return {
            "1": "Gasal",
            "semester 1": "Gasal",
            "2": "Genap",
            "semester 2": "Genap",
        }.get(normalized, ERaporService._localized(value))

    @staticmethod
    def _report_type_label(value: Any) -> str:
        normalized = str(value or "").strip().lower()
        return {
            "sts": "Sumatif Tengah Semester",
            "sumatif_tengah_semester": "Sumatif Tengah Semester",
            "sas": "Sumatif Akhir Semester",
            "sumatif_akhir_semester": "Sumatif Akhir Semester",
            "sat": "Sumatif Akhir Tahun",
            "sumatif_akhir_tahun": "Sumatif Akhir Tahun",
        }.get(normalized, ERaporService._localized(value))

    @staticmethod
    def _phase_label(value: Any) -> str:
        normalized = str(value or "").strip().upper()
        if normalized in {"A", "B", "C", "D", "E", "F"}:
            return f"Fase {normalized}"
        return ERaporService._localized(value, "")

    async def get_student_reports(
        self, student_id: int, jenjang: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        raw_reports = await self.repo.get_student_reports(
            student_id=student_id, jenjang=jenjang
        )
        return self._map_report_rows(raw_reports, student_id)

    def _map_report_rows(
        self, raw_reports: List[Dict[str, Any]], student_id: int
    ) -> List[Dict[str, Any]]:
        reports = []
        for report in raw_reports:
            report_id = int(report["id"])
            reports.append(
                {
                    "id": report_id,
                    "student_id": int(report.get("student_id") or student_id),
                    "student_name": self._localized(report.get("student_name")),
                    "jenis_rapor": self._report_type_label(
                        report.get("jenis_rapor")
                    ),
                    "kelas": self._localized(report.get("kelas")),
                    "semester": self._semester_label(report.get("semester")),
                    "tahun_ajaran": self._localized(report.get("tahun_ajaran")),
                    "rata_rata_nilai": self._number(
                        report.get("rata_rata_nilai")
                    ),
                    "catatan_wali_kelas": self._localized(
                        report.get("catatan_wali_kelas"), ""
                    ),
                    "status_keputusan": self._localized(
                        report.get("status_keputusan"), ""
                    ),
                    "file_rapor_pdf": f"/e-rapor/pdf/{report_id}",
                    "file_name": self._file_name(report, report_id),
                }
            )
        return reports

    async def sync_student_reports(
        self, student_id: int, jenjang: Optional[str], cursor: Optional[str]
    ) -> Dict[str, Any]:
        sync = await self.repo.get_student_reports_sync(
            student_id=student_id,
            jenjang=jenjang,
            cursor=cursor,
        )
        sync["items"] = self._map_report_rows(sync["items"], student_id)
        return sync

    @staticmethod
    def _number(value: Any) -> float:
        try:
            return float(value or 0.0)
        except (TypeError, ValueError):
            return 0.0

    @classmethod
    def _file_name(cls, report: Dict[str, Any], report_id: int) -> str:
        name = cls._localized(report.get("file_name"), "")
        if name:
            return name
        return f"Rapor_{report_id}.pdf"

    async def get_report_detail(
        self,
        rapor_id: int,
        student_id: int,
        jenjang: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        report = await self.repo.get_report_card_details(
            rapor_id=rapor_id,
            student_id=student_id,
            jenjang=jenjang,
        )
        if not report:
            return None

        identity = await self.repo.get_student_identity(student_id)
        subjects = [
            self._map_subject(subject, index)
            for index, subject in enumerate(report.get("subjects") or [], start=1)
        ]
        local_subjects = [
            self._map_subject(subject, index)
            for index, subject in enumerate(
                report.get("muatan_lokal") or [], start=1
            )
        ]
        attachment_id = report.get("attachment_id")
        report_id = int(report.get("id") or rapor_id)
        return {
            "id": report_id,
            "student_id": int(report.get("student_id") or student_id),
            "student_name": self._localized(
                report.get("student_name") or identity.get("student_name")
            ),
            "jenis_rapor": self._report_type_label(report.get("jenis_rapor")),
            "kelas": self._localized(
                report.get("kelas") or identity.get("kelas")
            ),
            "semester": self._semester_label(report.get("semester")),
            "tahun_ajaran": self._localized(report.get("tahun_ajaran")),
            "fase": self._phase_label(report.get("fase")),
            "rata_rata_nilai": self._number(report.get("rata_rata_nilai")),
            "catatan_wali_kelas": self._localized(
                report.get("catatan_wali_kelas"), ""
            ),
            "status_keputusan": self._localized(
                report.get("status_keputusan"), ""
            ),
            "file_rapor_pdf": f"/e-rapor/pdf/{report_id}",
            "file_name": self._file_name(report, report_id),
            "subjects": subjects,
            "muatan_lokal": local_subjects,
            "nis": self._localized(identity.get("nis"), ""),
            "nisn": self._localized(identity.get("nisn"), ""),
            "nama_sekolah": self._localized(report.get("nama_sekolah"), ""),
            "alamat_sekolah": self._localized(
                report.get("alamat_sekolah"), ""
            ),
            "tanggal_pengesahan": self._localized(
                report.get("tanggal_pengesahan"), ""
            ),
            "wali_kelas": self._localized(report.get("wali_kelas"), ""),
            "has_pdf_attachment": bool(attachment_id),
        }

    @classmethod
    def _map_subject(cls, line: Dict[str, Any], index: int) -> Dict[str, Any]:
        subject_id = line.get("subject_id")
        if isinstance(subject_id, (list, tuple)):
            subject_id = subject_id[0] if subject_id else None
        score = line.get("nilai_akhir")
        if score is None:
            score = line.get("sts")
        if score is None:
            score = line.get("total_nilai")
        # Kolom sumber:
        #   note  / cp_kompetensi → capaian_kompetensi (predikat singkat per mapel)
        #   note2 / ct_kompetensi → catatan_kompetensi (deskripsi/narasi kompetensi)
        capaian = (
            line.get("capaian_kompetensi")
            or line.get("note")
            or line.get("cp_kompetensi")
            or line.get("predikat")
        )
        catatan = (
            line.get("catatan_kompetensi")
            or line.get("note2")
            or line.get("ct_kompetensi")
            or line.get("catatan")
        )
        return {
            "id": int(line.get("id") or index),
            "subject_id": int(subject_id) if subject_id is not None else None,
            "subject_name": cls._localized(line.get("subject_name")),
            "nilai_pengetahuan": cls._number(
                line.get("nilai_pengetahuan")
                if line.get("nilai_pengetahuan") is not None
                else score
            ),
            "nilai_keterampilan": cls._number(line.get("nilai_keterampilan")),
            "nilai_akhir": cls._number(score),
            "predikat": cls._localized(capaian),           # capaian kompetensi (note)
            "catatan": cls._localized(catatan, ""),         # catatan kompetensi (note2)
        }

    async def get_rapor_pdf_bytes(
        self, rapor_id: int, student_id: int, jenjang: Optional[str] = None
    ) -> Optional[Tuple[bytes, str]]:
        attachment = await self.repo.attachment_bytes(
            rapor_id=rapor_id,
            student_id=student_id,
            jenjang=jenjang,
        )
        if attachment:
            return attachment

        detail = await self.get_report_detail(
            rapor_id=rapor_id,
            student_id=student_id,
            jenjang=jenjang,
        )
        if not detail:
            return None
        pdf_bytes = await asyncio.to_thread(self._generate_pdf_from_template, detail)
        student_name = str(detail.get("student_name") or "").strip()
        student_name = student_name.replace(" ", "_").replace("/", "-").replace("\\", "-")
        filename = f"E-Rapor_{student_name or f'Siswa_{student_id}'}_ID{rapor_id}.pdf"
        return pdf_bytes, filename

    @staticmethod
    def _get_libreoffice_cmd() -> str:
        if sys.platform.startswith("win"):
            for candidate in (
                r"C:\Program Files\LibreOffice\program\soffice.exe",
                r"C:\Program Files (x86)\LibreOffice\program\soffice.exe",
            ):
                if os.path.exists(candidate):
                    return candidate
        command = shutil.which("soffice") or shutil.which("libreoffice")
        if command:
            return command
        raise FileNotFoundError(
            "LibreOffice tidak ditemukan. Pasang LibreOffice untuk membuat PDF E-Rapor."
        )

    def _generate_pdf_from_template(self, detail: Dict[str, Any]) -> bytes:
        if not self.template_path.is_file():
            raise FileNotFoundError(
                f"Template Word tidak ditemukan di: {self.template_path}"
            )
        nis_nisn = [
            value for value in (detail.get("nis"), detail.get("nisn")) if value
        ]

        # 1. Pastikan subjects tidak kosong, jika kosong sediakan 1 baris dummy
        raw_subjects = detail.get("subjects") or []
        formatted_subjects = [
            {**subject, "no": index}
            for index, subject in enumerate(raw_subjects, start=1)
        ]
        if not formatted_subjects:
            formatted_subjects = [{
                "no": "",
                "subject_name": "",
                "nilai_pengetahuan": "",
                "nilai_keterampilan": "",
                "nilai_akhir": "",
                "predikat": "",      # capaian kompetensi (note)
                "catatan": ""        # catatan kompetensi (note2)
            }]

        # 2. Pastikan muatan_lokal tidak kosong, jika kosong sediakan 1 baris dummy
        raw_mulok = detail.get("muatan_lokal") or []
        formatted_mulok = [
            {**subject, "no": index}
            for index, subject in enumerate(raw_mulok, start=1)
        ]
        if not formatted_mulok:
            formatted_mulok = [{
                "no": "",
                "subject_name": "",
                "nilai_pengetahuan": "",
                "nilai_keterampilan": "",
                "nilai_akhir": "",
                "predikat": "",      # capaian kompetensi (note)
                "catatan": ""        # catatan kompetensi (note2)
            }]

        template_context = {
            **detail,
            "nis_nisn": " / ".join(nis_nisn),
            "subjects": formatted_subjects,
            "muatan_lokal": formatted_mulok,
            "mulok": formatted_mulok,  # Alias untuk mencocokkan jika template memanggil 'mulok'
        }

        document = DocxTemplate(str(self.template_path))
        document.render(template_context)
        with tempfile.TemporaryDirectory() as temp_dir:
            output_dir = Path(temp_dir)
            docx_path = output_dir / "rapor_output.docx"
            document.save(str(docx_path))
            profile_path = output_dir / "libreoffice-profile"
            command = [
                self._get_libreoffice_cmd(),
                "--headless",
                f"-env:UserInstallation={profile_path.as_uri()}",
                "--convert-to",
                "pdf",
                "--outdir",
                str(output_dir),
                str(docx_path),
            ]
            subprocess.run(
                command,
                check=True,
                capture_output=True,
                timeout=60,
            )
            pdf_path = output_dir / "rapor_output.pdf"
            return pdf_path.read_bytes()