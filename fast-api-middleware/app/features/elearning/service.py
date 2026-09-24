import re
from typing import Dict, Any, List, Optional
from app.features.elearning.repository import ElearningRepository


class ElearningService:
    def __init__(self, repo: ElearningRepository):
        self.repo = repo

    def _parse_many2one(self, val: Any, fallback: str = '-') -> str:
        if isinstance(val, list) and len(val) > 1:
            return str(val[1])
        if isinstance(val, str):
            return val
        return fallback

    def _strip_html(self, raw: Any) -> str:
        """Hapus tag HTML dari field description Odoo."""
        if not raw or raw is False:
            return ''
        return re.sub(r'<[^>]+>', '', str(raw)).strip()

    def _map_slide_type(self, slide_category: str, slide_type: str) -> str:
        """Normalkan tipe materi ke kategori yang dikenali Flutter."""

        category = (slide_category or '').lower()
        slide = (slide_type or '').lower()

        if slide == 'scorm' or category == 'scorm':
            return 'scorm'

        if slide == 'video' or category == 'video':
            return 'video'

        if slide in ('quiz', 'question') or category in ('quiz', 'question'):
            return 'quiz'

        return 'document'

    def _localized_text(self, val: Any, fallback: str = '-') -> str:
        if isinstance(val, dict):
            return str(val.get('id_ID') or val.get('en_US') or next(iter(val.values()), fallback))
        if val is not None and val is not False and val != '':
            return str(val)
        return fallback

    def get_courses_list(
        self, uid: int, password: str,
        partner_id: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        raw_courses = self.repo.get_published_courses(
            uid=uid, password=password, partner_id=partner_id
        )
        result = []
        for c in raw_courses:
            result.append({
                "id": c.get("id"),
                "title": self._localized_text(c.get("name"), "Kursus"),
                "teacher_name": self._parse_many2one(c.get("user_id"), "-"),
                "total_slides": int(c.get("total_slides") or 0),
                "description": self._strip_html(c.get("description")),
            })
        return result

    def get_course_detail(
        self, uid: int, password: str, course_id: int
    ) -> Optional[Dict[str, Any]]:
        course = self.repo.get_course_by_id(uid=uid, password=password, course_id=course_id)
        if not course:
            return None

        raw_slides = self.repo.get_slides_by_course_id(
            uid=uid, password=password, course_id=course_id
        )

        slides = []
        for s in raw_slides:
            slides.append({
                "id": s.get("id"),
                "title": self._localized_text(s.get("name"), "Materi"),
                "material_type": self._map_slide_type(
                    str(s.get("slide_category") or ''),
                    str(s.get("slide_type") or '')
                ),
                "download_url": s.get("download_url"),
                "sequence": int(s.get("sequence") or 0),
            })

        return {
            "id": course.get("id"),
            "title": self._localized_text(course.get("name"), "Kursus"),
            "teacher_name": self._parse_many2one(course.get("user_id"), "-"),
            "description": self._strip_html(course.get("description")),
            "total_slides": int(course.get("total_slides") or 0),
            "slides": slides,
        }

    def get_scorm_package(
        self, uid: int, password: str, slide_id: int
    ) -> Optional[tuple]:
        res = self.repo.get_scorm_attachment(uid=uid, password=password, slide_id=slide_id)
        if not res:
            return None
        return res['content'], res['filename'], res['mimetype']

