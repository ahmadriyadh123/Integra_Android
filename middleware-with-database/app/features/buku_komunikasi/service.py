from typing import Any, Dict, Optional

from app.features.buku_komunikasi.repository import BukuKomunikasiRepository


class BukuKomunikasiService:
    def __init__(self, repo: BukuKomunikasiRepository):
        self.repo = repo

    async def get_buku_komunikasi(
        self, student_id: int, jenjang: str = "sd"
    ) -> Optional[Dict[str, Any]]:
        header = await self.repo.get_buku_catatan_header(
            student_id=student_id, jenjang=jenjang
        )
        if not header:
            return None

        lines = await self.repo.get_buku_catatan_lines(
            bukpeng_id=header["id"], jenjang=jenjang
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

    @staticmethod
    def _validate_day(day: str) -> str:
        normalized = day.strip().lower()
        if normalized not in {"senin", "selasa", "rabu", "kamis", "jumat"}:
            raise ValueError(
                f"Hari '{day}' tidak valid. Pilih salah satu dari: "
                "senin, selasa, rabu, kamis, jumat."
            )
        return normalized

    async def save_daily_note(
        self,
        student_id: int,
        line_id: int,
        day: str,
        note_text: str,
        month: Optional[str] = None,
        week: Optional[int] = None,
        jenjang: str = "sd",
    ) -> bool:
        normalized_day = self._validate_day(day)
        if line_id > 0:
            return await self.repo.update_daily_note(
                student_id=student_id,
                line_id=line_id,
                day=normalized_day,
                note_text=note_text,
                jenjang=jenjang,
            )
        if not month or not month.strip():
            raise ValueError("Bulan wajib diisi untuk catatan pekan baru.")
        if week is None or week < 1:
            raise ValueError("Pekan harus berupa angka positif.")
        return await self.repo.create_daily_note_line(
            student_id=student_id,
            pekan_ke=week,
            bulan=month.strip(),
            day=normalized_day,
            note_text=note_text,
            jenjang=jenjang,
        )

    async def save_parent_feedback(
        self,
        student_id: int,
        line_id: int,
        day: str,
        feedback_text: str,
        jenjang: str = "sd",
    ) -> bool:
        normalized_day = self._validate_day(day)
        return await self.repo.update_parent_feedback(
            student_id=student_id,
            line_id=line_id,
            day=normalized_day,
            feedback_text=feedback_text,
            jenjang=jenjang,
        )