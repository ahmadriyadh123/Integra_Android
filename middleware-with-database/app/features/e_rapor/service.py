# app/features/e_rapor/service.py
from typing import List, Dict, Any, Optional
from app.features.e_rapor.repository import ERaporRepository

class ERaporService:
    def __init__(self, repo: ERaporRepository):
        self.repo = repo

    def _str(self, val: Any, fallback: str = '-') -> str:
        return str(val) if val and val is not None and val is not False else fallback

    async def get_student_reports(self, student_id: int) -> List[Dict[str, Any]]:
        raw_reports = await self.repo.get_student_reports(student_id=student_id)
        reports = []
        for r in raw_reports:
            file_pdf = r.get("file_url")
            if not file_pdf and r.get("attachment_id"):
                file_pdf = f"/web/content/{r.get('attachment_id')}?download=true"

            reports.append({
                "id": r.get("id"),
                "student_id": r.get("student_id"),
                "student_name": self._str(r.get("student_name")),
                "kelas": self._str(r.get("kelas_name")),
                "semester": self._str(r.get("semester")),
                "tahun_ajaran": self._str(r.get("tahun_ajaran_name")),
                "rata_rata_nilai": float(r.get("nilai_rata_rata") or 0.0),
                "catatan_wali_kelas": self._str(r.get("catatan_wali_kelas")),
                "file_rapor_pdf": file_pdf,
                "file_name": self._str(r.get("file_name")),
            })
        return reports

    async def get_report_detail(self, rapor_id: int, student_id: int) -> Optional[Dict[str, Any]]:
        raw_detail = await self.repo.get_report_card_details(rapor_id=rapor_id, student_id=student_id)
        if not raw_detail:
            return None

        file_pdf = raw_detail.get("file_url")
        if not file_pdf and raw_detail.get("attachment_id"):
            file_pdf = f"/web/content/{raw_detail.get('attachment_id')}?download=true"

        return {
            "id": raw_detail.get("id"),
            "student_id": raw_detail.get("student_id"),
            "student_name": self._str(raw_detail.get("student_name")),
            "kelas": self._str(raw_detail.get("kelas_name")),
            "rata_rata_nilai": float(raw_detail.get("nilai_rata_rata") or 0.0),
            "catatan_wali_kelas": self._str(raw_detail.get("catatan_wali_kelas")),
            "file_rapor_pdf": file_pdf,
            "file_name": self._str(raw_detail.get("file_name")),
            "subjects": raw_detail.get("subjects", [])
        }