from pydantic import BaseModel
from typing import List, Optional

class CalendarItemResponse(BaseModel):
    id: int
    kelas: str
    semester: str
    tahun_ajaran: str
    link_dokumen: str
    status: Optional[str] = None


class AcademicCalendarSummaryResponse(BaseModel):
    total_records: int
    calendars: List[CalendarItemResponse]


class APIResponseCalendar(BaseModel):
    success: bool
    message: str
    data: AcademicCalendarSummaryResponse
