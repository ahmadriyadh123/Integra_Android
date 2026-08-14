# app/features/elearning/service.py
import re
from typing import Dict, Any, List, Optional
from app.features.elearning.repository import ElearningRepository

class ElearningService:
    def __init__(self, repo: ElearningRepository):
        self.repo = repo

    def _strip_html(self, raw: Any) -> str:
        """Hapus tag HTML dari field description."""
        if not raw or raw is False:
            return ''
        return re.sub(r'<[^>]+>', '', str(raw)).strip()

    def _map_slide_type(self, slide_category: str, slide_type: str) -> str:
        """Normalkan tipe materi ke kategori yang dikenali Flutter."""
        val = (slide_category or slide_type or '').lower()
        if val in ('video',):
            return 'video'
        if val in ('scorm',):
            return 'scorm'
        if val in ('quiz', 'question',):
            return 'quiz'
        return 'document'  # pdf, infographic, dsb

    async def get_courses_list(self) -> List[Dict[str, Any]]:
        raw_courses = await self.repo.get_published_courses()
        result = []
        for c in raw_courses:
            result.append({
                "id": c.get("id"),
                "title": str(c.get("name") or "Kursus"),
                "teacher_name": str(c.get("teacher_name") or "-"),
                "total_slides": int(c.get("total_slides") or 0),
                "description": self._strip_html(c.get("description")),
            })
        return result

    async def get_course_detail(self, course_id: int) -> Optional[Dict[str, Any]]:
        course = await self.repo.get_course_by_id(course_id=course_id)
        if not course:
            return None

        raw_slides = await self.repo.get_slides_by_course_id(course_id=course_id)
        slides = []
        for s in raw_slides:
            slides.append({
                "id": s.get("id"),
                "title": str(s.get("name") or "Materi"),
                "material_type": self._map_slide_type(
                    str(s.get("slide_category") or ''),
                    str(s.get("slide_type") or '')
                ),
                "download_url": s.get("download_url"),
                "sequence": int(s.get("sequence") or 0),
            })

        return {
            "id": course.get("id"),
            "title": str(course.get("name") or "Kursus"),
            "teacher_name": str(course.get("teacher_name") or "-"),
            "description": self._strip_html(course.get("description")),
            "total_slides": int(course.get("total_slides") or 0),
            "slides": slides,
        }