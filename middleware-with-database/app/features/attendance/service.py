
from typing import List
from app.features.attendance.repository import AttendanceRepository
from app.features.attendance.schemas import AttendanceRecordResponse

class AttendanceService:
    def __init__(self, repository: AttendanceRepository):
        self.repository = repository

    async def get_student_history(self, student_id: int, limit: int = 100) -> List[AttendanceRecordResponse]:
        records = await self.repository.get_by_student_id(student_id=student_id, limit=limit)
        return [AttendanceRecordResponse(**record) for record in records]