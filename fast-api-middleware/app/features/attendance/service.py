from typing import List, Dict, Any
from app.features.attendance.repository import AttendanceRepository

class AttendanceService:
    def __init__(self, repo: AttendanceRepository):
        self.repo = repo

    def _parse_many2one(self, val: Any, fallback: str = '-') -> str:
        "Helper untuk membaca nilai [id, name] bawaan Odoo Many2one"
        if isinstance(val, list) and len(val) > 1:
            return str(val[1])
        if isinstance(val, str):
            return val
        return fallback
    
    def get_student_history(self, uid: int, password: str, student_id: int = None, limit: int = 100) -> List[Dict[str, Any]]:
            raw_records = self.repo.get_attendance_history(uid=uid, password=password, student_id=student_id, limit=limit)
            
            cleaned_data = []
            for item in raw_records:
                attendance_date = item.get("attendance_date")
                cleaned_data.append({
                    "id": item.get("id"),
                    "student_name": student_name,
                    "course_name": self._parse_many2one(item.get("course_id"), "-"),
                    "batch_name": self._parse_many2one(item.get("batch_id"), "-"),
                    "attendance_date": str(attendance_date) if attendance_date else None,
                    "present": bool(item.get("present")),
                    "excused": bool(item.get("excused")),
                    "absent": bool(item.get("absent")),
                    "sick": bool(item.get("sick")),
                    "status": str(item.get("status") or ""),
                    "remark": str(item.get("remark") or "-"),
                })
                
            return cleaned_data

    def get_student_summary(self, user_id: int) -> Dict[str, Any]:
        records = self.repo.get_attendance_history(uid=user_id, password="", limit=365)
        
        total_days = len(records)
        total_present = sum(1 for r in records if r['present'])
        total_sick = sum(1 for r in records if r['sick'])
        total_excused = sum(1 for r in records if r['excused'])
        total_absent = sum(1 for r in records if r['absent'])
        
        percentage = (total_present / total_days * 100) if total_days > 0 else 0.0

        return {
            "total_days": total_days,
            "total_present": total_present,
            "total_sick": total_sick,
            "total_excused": total_excused,
            "total_absent": total_absent,
            "percentage": round(percentage, 2)
        }