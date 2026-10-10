import re
import html
from datetime import datetime, timedelta, timezone
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

    def _message_text(self, raw: Any) -> str:
        if not raw or raw is False:
            return ''
        text = re.sub(r'<br\s*/?>|</p>|</div>', '\n', str(raw), flags=re.IGNORECASE)
        return html.unescape(re.sub(r'<[^>]+>', '', text)).strip()

    def get_course_messages(
        self,
        uid: int,
        password: str,
        course_id: int,
        partner_id: Optional[int] = None,
    ) -> Optional[List[Dict[str, Any]]]:
        messages = self.repo.get_course_messages(
            uid=uid,
            password=password,
            course_id=course_id,
        )
        if messages is None:
            return None

        result = []
        for message in reversed(messages):
            author = message.get('author_id')
            author_id = author[0] if isinstance(author, (list, tuple)) and author else None
            author_name = (
                str(author[1])
                if isinstance(author, (list, tuple)) and len(author) > 1
                else '-'
            )
            result.append({
                'id': int(message.get('id') or 0),
                'author_name': author_name,
                'body': self._message_text(message.get('body')),
                'created_at': str(message.get('date') or ''),
                'is_own': (
                    partner_id is not None
                    and str(author_id) == str(partner_id)
                ),
            })
        return result

    def post_course_message(
        self,
        uid: int,
        password: str,
        course_id: int,
        body: str,
    ) -> Optional[int]:
        message = body.strip()
        if not message:
            raise ValueError('Pesan tidak boleh kosong.')
        escaped_body = html.escape(message).replace('\n', '<br/>')
        return self.repo.post_course_message(
            uid=uid,
            password=password,
            course_id=course_id,
            body=escaped_body,
        )

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
        progress_by_course = (
            self.repo.get_progress_by_course(uid, password, partner_id)
            if partner_id is not None
            else {}
        )
        return self._map_courses(raw_courses, progress_by_course)

    def get_courses_sync(
        self,
        uid: int,
        password: str,
        partner_id: Optional[int],
        cursor: Optional[datetime],
    ) -> Dict[str, Any]:
        sync_started_at = datetime.now(timezone.utc)
        full_sync = cursor is None

        if full_sync:
            items = self.get_courses_list(uid, password, partner_id)
            removed_ids: List[int] = []
        else:
            normalized_cursor = (
                cursor.replace(tzinfo=timezone.utc)
                if cursor.tzinfo is None
                else cursor.astimezone(timezone.utc)
            )
            safe_cursor = min(normalized_cursor, sync_started_at)
            modified_after = (
                safe_cursor - timedelta(minutes=2)
            ).astimezone(timezone.utc).strftime('%Y-%m-%d %H:%M:%S')
            raw_courses, removed_ids = self.repo.get_course_sync_changes(
                uid=uid,
                password=password,
                partner_id=partner_id,
                modified_after=modified_after,
            )
            progress_by_course = (
                self.repo.get_progress_by_course(uid, password, partner_id)
                if partner_id is not None
                else {}
            )
            items = self._map_courses(raw_courses, progress_by_course)

        return {
            'items': items,
            'removed_ids': removed_ids,
            'next_cursor': sync_started_at.isoformat().replace('+00:00', 'Z'),
            'full_sync': full_sync,
        }

    def _map_courses(
        self,
        raw_courses: List[Dict[str, Any]],
        progress_by_course: Dict[int, set[int]],
    ) -> List[Dict[str, Any]]:
        result = []
        for c in raw_courses:
            total_slides = int(c.get("total_slides") or 0)
            completed_slides = len(progress_by_course.get(int(c["id"]), set()))
            result.append({
                "id": c.get("id"),
                "title": self._localized_text(c.get("name"), "Kursus"),
                "teacher_name": self._parse_many2one(c.get("user_id"), "-"),
                "total_slides": total_slides,
                "completed_slides": completed_slides,
                "progress_percent": (
                    round(completed_slides * 100 / total_slides)
                    if total_slides
                    else 0
                ),
                "description": self._strip_html(c.get("description")),
            })
        return result

    def get_course_detail(
        self,
        uid: int,
        password: str,
        course_id: int,
        partner_id: Optional[int] = None,
    ) -> Optional[Dict[str, Any]]:
        course = self.repo.get_course_by_id(uid=uid, password=password, course_id=course_id)
        if not course:
            return None

        raw_slides = self.repo.get_slides_by_course_id(
            uid=uid, password=password, course_id=course_id
        )
        completed_slide_ids = (
            self.repo.get_completed_slide_ids(
                uid,
                password,
                course_id,
                partner_id,
            )
            if partner_id is not None
            else set()
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
                "is_completed": int(s["id"]) in completed_slide_ids,
            })

        total_slides = len(slides)
        completed_slides = sum(slide["is_completed"] for slide in slides)
        return {
            "id": course.get("id"),
            "title": self._localized_text(course.get("name"), "Kursus"),
            "teacher_name": self._parse_many2one(course.get("user_id"), "-"),
            "description": self._strip_html(course.get("description")),
            "total_slides": total_slides,
            "completed_slides": completed_slides,
            "progress_percent": (
                round(completed_slides * 100 / total_slides)
                if total_slides
                else 0
            ),
            "slides": slides,
        }

    def mark_slide_completed(
        self,
        uid: int,
        password: str,
        course_id: int,
        slide_id: int,
        partner_id: int,
        source: str,
        completion_status: Optional[str] = None,
    ) -> bool:
        return self.repo.mark_slide_completed(
            uid=uid,
            password=password,
            course_id=course_id,
            slide_id=slide_id,
            partner_id=partner_id,
            source=source,
            completion_status=completion_status,
        )

    def get_scorm_package(
        self, uid: int, password: str, slide_id: int
    ) -> Optional[tuple]:
        res = self.repo.get_scorm_attachment(uid=uid, password=password, slide_id=slide_id)
        if not res:
            return None
        return res['content'], res['filename'], res['mimetype']
