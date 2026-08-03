from typing import Dict, Any, List, Optional
from app.features.elearning.repository import ElearningRepository

class ElearningService:
    def __init__(self, repo: ElearningRepository):
        self.repo = repo

    def _parse_many2one(self, val: Any, fallback: str = 'Pengajar') -> str:
        if isinstance(val, list) and len(val) > 1:
            return str(val[1])
        if isinstance(val, str):
            return val
        return fallback

    def get_courses_list(self, uid: int, password: str) -> List[Dict[str, Any]]:
        raw_courses = self.repo.get_published_courses(uid=uid, password=password)

        cleaned_courses = []
        for c in raw_courses:
            total_slides = int(c.get("total_slides") or 0)
            cleaned_courses.append({
                "id": c.get("id"),
                "title": str(c.get("name") or "Mata Pelajaran"),
                "teacher_name": self._parse_many2one(c.get("user_id"), "Pengajar"),
                "total_chapters": total_slides,
                "progress_percentage": 0.0  # Kalkulasi progres default
            })

        return cleaned_courses

    def get_course_detail(self, uid: int, password: str, course_id: int) -> Optional[Dict[str, Any]]:
        course = self.repo.get_course_by_id(uid=uid, password=password, course_id=course_id)
        if not course:
            return None

        raw_slides = self.repo.get_slides_by_course_id(uid=uid, password=password, course_id=course_id)

        materials = []
        for s in raw_slides:
            slide_cat = str(s.get("slide_category") or s.get("slide_type") or "document")
            materials.append({
                "id": s.get("id"),
                "title": str(s.get("name") or "Materi Pembelajaran"),
                "material_type": slide_cat,
                "file_url": s.get("url"),
                "is_completed": False
            })

        return {
            "id": course.get("id"),
            "title": str(course.get("name") or "Mata Pelajaran"),
            "teacher_name": self._parse_many2one(course.get("user_id"), "Pengajar"),
            "description": str(course.get("description") or "Deskripsi kursus"),
            "chapters": [
                {
                    "id": 1,
                    "chapter_name": "Materi Pembelajaran",
                    "description": "Daftar slide & modul E-Learning",
                    "materials": materials
                }
            ]
        }