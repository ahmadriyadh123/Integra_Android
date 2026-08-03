from pydantic import BaseModel
from typing import List, Optional

class CalendarItemResponse(BaseModel):
    id: int
    kelas: str                  # op_course.name
    semester: str               # op_academic_term.name
    tahun_ajaran: str           # op_academic_year.name
    link_dokumen: str           # kaldik_sd.link_dokumen

class AcademicCalendarSummaryResponse(BaseModel):
    total_records: int
    calendars: List[CalendarItemResponse]

class APIResponseCalendar(BaseModel):
    success: bool
    message: str
    data: AcademicCalendarSummaryResponse