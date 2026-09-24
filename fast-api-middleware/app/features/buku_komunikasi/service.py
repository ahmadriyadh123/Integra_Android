from typing import Dict, Any, Optional
from app.features.buku_komunikasi.repository import BukuKomunikasiRepository

class BukuKomunikasiService:
    def __init__(self, repo: BukuKomunikasiRepository):
        self.repo = repo

    def _parse_many2one(self, val: Any, fallback: str = '-') -> str:
        if isinstance(val, list) and len(val) > 1:
            return str(val[1])
        if isinstance(val, str):
            return val
        return fallback

    def get_buku_komunikasi(self, uid: int, password: str, student_id: int, jenjang: str = 'sd') -> Optional[Dict[str, Any]]:
        header = self.repo.get_buku_catatan_header(uid=uid, password=password, student_id=student_id, jenjang=jenjang)
        if not header:
            return None

        lines = self.repo.get_buku_catatan_lines(
            uid=uid, password=password, bukpeng_id=header['id'], jenjang=jenjang
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
            "student_name": self._parse_many2one(header.get("student_id"), "-"),
            "kelas": self._parse_many2one(header.get("kelas_id"), "-"),
            "tahun_ajaran": self._parse_many2one(header.get("tahun_id"), "-"),
            "status": str(header.get("status") or "-"),
            "lines": formatted_lines
        }
        
    def save_feedback(self, uid: int, password: str,  line_id: int, day: str, feedback_text: str, jenjang: str = 'sd') -> bool:
        allowed_days = ["senin", "selasa", "rabu", "kamis", "jumat"]
        if day.lower() not in allowed_days:
            raise ValueError(f"Hari '{day}' tidak valid. Pilih salah satu dari: {allowed_days}")

        return self.repo.update_parent_feedback(
            uid=uid,
            password=password,
            line_id=line_id,
            day=day,
            feedback_text=feedback_text,
            jenjang=jenjang
        )

    def save_daily_note(self, uid: int, password: str, student_id: int, line_id: int, day: str, note_text: str, month: Optional[str] = None, week: Optional[int] = None, jenjang: str = 'sd') -> bool:
        allowed_days = ["senin", "selasa", "rabu", "kamis", "jumat"]
        if day.lower() not in allowed_days:
            raise ValueError(f"Hari '{day}' tidak valid. Pilih salah satu dari: {allowed_days}")

        # Jika line_id > 0, langsung update
        if line_id > 0:
            return self.repo.update_daily_note(
                uid=uid,
                password=password,
                line_id=line_id,
                day=day,
                note_text=note_text,
                jenjang=jenjang
            )
        
        # Jika line_id == 0, cari header lalu buatkan baris pekan baru
        header = self.repo.get_buku_catatan_header(uid=uid, password=password, student_id=student_id, jenjang=jenjang)
        if not header:
            raise ValueError("Data buku komunikasi siswa tidak ditemukan di Odoo")
            
        return self.repo.create_daily_note_line(
            uid=uid,
            password=password,
            bukpeng_id=header['id'],
            pekan_ke=week or 1,
            bulan=month or "Januari",
            day=day,
            note_text=note_text,
            jenjang=jenjang
        )