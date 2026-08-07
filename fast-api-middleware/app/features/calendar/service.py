from typing import Dict, Any, List
from app.features.calendar.repository import CalendarRepository


class CalendarService:
    def __init__(self, repo: CalendarRepository):
        self.repo = repo

    def _parse_many2one(self, val: Any, fallback: str = '-') -> str:
        """Helper membaca nilai [id, name] bawaan Odoo Many2one."""
        if isinstance(val, list) and len(val) > 1:
            return str(val[1])
        if isinstance(val, str):
            return val
        return fallback

    def get_calendars_list(self, uid: int, password: str) -> Dict[str, Any]:
        raw_records = self.repo.get_academic_calendars(uid=uid, password=password)

        calendars = []
        for item in raw_records:
            calendars.append({
                "id": item.get("id"),
                "kelas": self._parse_many2one(item.get("kelas_id"), "-"),
                "semester": self._parse_many2one(item.get("semester_id"), "-"),
                "tahun_ajaran": self._parse_many2one(item.get("tahun_id"), "-"),
                "link_dokumen": str(item.get("link_dokumen") or ""),
                "status": str(item.get("status") or ""),
            })

        return {
            "total_records": len(calendars),
            "calendars": calendars
        }
