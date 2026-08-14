# app/features/buku_komunikasi/service.py
from typing import Dict, Any, Optional
from app.features.buku_komunikasi.repository import BukuKomunikasiRepository

class BukuKomunikasiService:
    def __init__(self, repo: BukuKomunikasiRepository):
        self.repo = repo

    async def get_buku_komunikasi(self, student_id: int, jenjang: str = 'sd') -> Optional[Dict[str, Any]]:
        header = await self.repo.get_buku_catatan_header(student_id=student_id, jenjang=jenjang)
        if not header:
            return None

        lines = await self.repo.get_buku_catatan_lines(
            bukpeng_id=header['id'], jenjang=jenjang
        )

        formatted_lines = []
        for line in lines:
            formatted_lines.append({
                "id": line.get("id"),
                "pekan_ke": line.get("pekan_ke") or 1,
                "bulan": str(line.get("bulan") or "-"),
                "senin": str(line.get("senin") or "-"),
                "feedback_senin": str(line.get("feedback_senin") or "-"),
                "selasa": str(line.get("selasa") or "-"),
                "feedback_selasa": str(line.get("feedback_selasa") or "-"),
                "rabu": str(line.get("rabu") or "-"),
                "feedback_rabu": str(line.get("feedback_rabu") or "-"),
                "kamis": str(line.get("kamis") or "-"),
                "feedback_kamis": str(line.get("feedback_kamis") or "-"),
                "jumat": str(line.get("jumat") or "-"),
                "feedback_jumat": str(line.get("feedback_jumat") or "-"),
            })

        return {
            "id": header.get("id"),
            "student_name": str(header.get("student_name") or "-"),
            "kelas": str(header.get("kelas_name") or "-"),
            "tahun_ajaran": str(header.get("tahun_name") or "-"),
            "status": str(header.get("status") or "-"),
            "lines": formatted_lines
        }

    async def save_feedback(self, line_id: int, day: str, feedback_text: str, jenjang: str = 'sd') -> bool:
        allowed_days = ["senin", "selasa", "rabu", "kamis", "jumat"]
        if day.lower() not in allowed_days:
            raise ValueError(f"Hari '{day}' tidak valid. Pilih salah satu dari: {allowed_days}")

        return await self.repo.update_parent_feedback(
            line_id=line_id,
            day=day,
            feedback_text=feedback_text,
            jenjang=jenjang
        )