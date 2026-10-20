
from datetime import datetime
from typing import List, Optional
from app.features.attendance.repository import AttendanceRepository
from app.features.attendance.schemas import AttendanceRecordResponse

class AttendanceService:
    def __init__(self, repository: AttendanceRepository):
        self.repository = repository

    async def get_student_history(self, student_id: int, limit: int = 100, changed_since: Optional[datetime] = None) -> List[AttendanceRecordResponse]:
        records = await self.repository.get_by_student_id(student_id=student_id, limit=limit, changed_since=changed_since)
        return [AttendanceRecordResponse(**record) for record in records]
