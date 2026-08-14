# app/features/attendance/schemas.py

from pydantic import BaseModel
from typing import List, Optional, Union
from datetime import datetime, date

class AttendanceRecordResponse(BaseModel):
    id: int
    student_id: int
    student_name: str
    course_name: Optional[str] = None
    batch_name: Optional[str] = None
    attendance_date: Union[datetime, date]
    present: bool = False
    excused: bool = False
    absent: bool = False
    sick: bool = False
    status: Optional[str] = "alfa"
    remark: Optional[str] = None

    class Config:
        from_attributes = True


class APIResponse(BaseModel):
    success: bool
    message: str
    data: List[AttendanceRecordResponse]