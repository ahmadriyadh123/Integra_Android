from pydantic import BaseModel
from typing import List, Optional
from datetime import date

class AttendanceRecordResponse(BaseModel):
    id: int
    student_name: str
    course_name: str
    batch_name: str
    attendance_date: Optional[date]
    present: bool
    excused: bool
    absent: bool
    sick: bool
    status: str
    remark: str

    class Config:
        from_attributes = True

class AttendanceSummaryResponse(BaseModel):
    total_days: int
    total_present: int
    total_sick: int
    total_excused: int
    total_absent: int
    percentage: float

class APIResponse(BaseModel):
    success: bool
    message: str
    data: List[AttendanceRecordResponse]