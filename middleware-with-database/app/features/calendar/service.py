# app/features/calendar/service.py
from typing import Dict, Any
from app.features.calendar.repository import CalendarRepository

class CalendarService:
    def __init__(self, repo: CalendarRepository):
        self.repo = repo

    async def get_calendars_list(self, jenjang: str = 'sd') -> Dict[str, Any]:
        raw_records = await self.repo.get_academic_calendars(jenjang=jenjang)
        calendars = []
        for item in raw_records:
            calendars.append({
                "id": item.get("id"),
                "kelas": str(item.get("kelas_name") or "-"),
                "semester": str(item.get("semester_name") or "-"),
                "tahun_ajaran": str(item.get("tahun_name") or "-"),
                "link_dokumen": str(item.get("link_dokumen") or ""),
                "status": str(item.get("status") or ""),
            })
        return {
            "total_records": len(calendars),
            "calendars": calendars
        }