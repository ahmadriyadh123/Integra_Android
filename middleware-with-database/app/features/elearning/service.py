import base64
import os
import re
from typing import Dict, Any, List, Optional
from app.features.elearning.repository import ElearningRepository
from app.core.config import settings

class ElearningService:
    def __init__(self, repo: ElearningRepository):
        self.repo = repo

    def _parse_many2one(self, val: Any, fallback: str = '-') -> str:
        if isinstance(val, list) and len(val) > 1:
            return str(val[1])
        if isinstance(val, str):
            return val
        return fallback

    def _localized_text(self, val: Any, fallback: str = '') -> str:
        if isinstance(val, dict):
            value = val.get('en_US')
            if value is None and val:
                value = next(iter(val.values()))
            return str(value) if value is not None else fallback
        if isinstance(val, str):
            return val
        return fallback

    def _strip_html(self, raw: Any) -> str:
        """Hapus tag HTML dari field description."""
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

    async def get_courses_list(self, partner_id: Optional[int] = None) -> List[Dict[str, Any]]:
        raw_courses = await self.repo.get_published_courses(partner_id=partner_id)
        result = []
        for c in raw_courses:
            result.append({
                "id": c.get("id"),
                "title": self._localized_text(c.get("name"), "Kursus"),
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
            "teacher_name": str(course.get("teacher_name") or "-"),
            "description": self._strip_html(course.get("description")),
            "total_slides": int(course.get("total_slides") or 0),
            "slides": slides,
        }

    async def get_scorm_package(self, slide_id: int):
        """Baca ZIP SCORM dari db_datas atau filestore Odoo."""
        slide = await self.repo.get_slide_content(slide_id=slide_id)
        if not slide or not slide.get("message_main_attachment_id"):
            return None

        attachment = await self.repo.get_attachment(
            attachment_id=slide["message_main_attachment_id"]
        )
        if not attachment:
            return None

        db_datas = attachment.get("db_datas")
        if db_datas:
            if isinstance(db_datas, memoryview):
                db_datas = bytes(db_datas)
            try:
                return (
                    base64.b64decode(db_datas),
                    attachment.get("name") or f"scorm_{slide_id}.zip",
                    attachment.get("mimetype") or "application/zip",
                )
            except (ValueError, TypeError):
                pass

        store_fname = attachment.get("store_fname")
        if store_fname:
            filepath = os.path.join(settings.ODOO_FILESTORE_PATH, store_fname)
            if os.path.isfile(filepath):
                with open(filepath, "rb") as file:
                    return (
                        file.read(),
                        attachment.get("name") or f"scorm_{slide_id}.zip",
                        attachment.get("mimetype") or "application/zip",
                    )
        return None