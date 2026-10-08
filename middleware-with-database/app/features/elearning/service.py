import base64
import io
import logging
import re
from typing import Dict, Any, List, Optional
from urllib.parse import urlsplit, urlunsplit
from zipfile import is_zipfile

import httpx

from app.features.elearning.repository import ElearningRepository
from app.core.config import get_attachment_path

logger = logging.getLogger(__name__)


def _public_attachment_url(base_url: str | None, attachment_id: int) -> str | None:
    if not isinstance(base_url, str) or not base_url.strip():
        return None
    try:
        parsed = urlsplit(base_url.strip())
    except ValueError:
        return None
    if (
        parsed.scheme not in {"http", "https"}
        or not parsed.hostname
        or parsed.username
        or parsed.password
    ):
        return None

    base_path = parsed.path.rstrip("/")
    return urlunsplit(
        (
            parsed.scheme,
            parsed.netloc,
            f"{base_path}/web/content/{attachment_id}",
            "download=true",
            "",
        )
    )


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
        """Read a SCORM ZIP from the tenant database, filestore, or public Odoo URL."""
        slide = await self.repo.get_slide_content(slide_id=slide_id)
        if not slide:
            return None

        # 1. Cari attachment ZIP asli via tabel relasi ir_attachment_slide_slide_rel
        attachment = await self.repo.get_scorm_attachment(slide_id=slide_id)

        # Fallback jika query relasi kosong
        if not attachment and slide.get("message_main_attachment_id"):
            attachment = await self.repo.get_attachment(
                attachment_id=slide["message_main_attachment_id"]
            )

        if not attachment:
            print(f"[E-LEARNING] Tidak ada attachment ZIP untuk slide_id: {slide_id}")
            return None

        print(f"[E-LEARNING] Attachment ZIP ditemukan -> ID: {attachment.get('id')}, Size: {attachment.get('file_size')} bytes")

        # 2. Ambil dari db_datas (PostgreSQL) jika ada
        db_datas = attachment.get("db_datas")
        if db_datas:
            if isinstance(db_datas, memoryview):
                db_datas = bytes(db_datas)
            try:
                decoded_bytes = base64.b64decode(db_datas)
                if len(decoded_bytes) > 5000:
                    return (
                        decoded_bytes,
                        attachment.get("name") or f"scorm_{slide_id}.zip",
                        "application/zip",
                    )
            except (ValueError, TypeError):
                pass

        # 3. Ambil dari Odoo Filestore Lokal
        store_fname = attachment.get("store_fname")
        if store_fname:
            file_path = get_attachment_path(
                store_fname,
                self.repo.db.info.get("tenant_database"),
            )
            if file_path and file_path.is_file() and file_path.stat().st_size > 5000:
                return (
                    file_path.read_bytes(),
                    attachment.get("name") or f"scorm_{slide_id}.zip",
                    "application/zip",
                )

        # Public Odoo attachments can be fetched over HTTP without JSON-RPC.
        if attachment.get("public") is True and attachment.get("id"):
            download_url = _public_attachment_url(
                self.repo.db.info.get("tenant_odoo_url", ""),
                int(attachment["id"]),
            )
            if download_url:
                try:
                    async with httpx.AsyncClient(
                        timeout=30.0,
                        follow_redirects=False,
                    ) as client:
                        response = await client.get(download_url)
                except httpx.RequestError as exc:
                    logger.warning(
                        "[elearning/scorm] Public attachment HTTP request failed "
                        "for slide_id=%s: %s",
                        slide_id,
                        exc,
                    )
                    return None

                if response.status_code == 200:
                    content = response.content
                    if len(content) > 5000 and is_zipfile(io.BytesIO(content)):
                        return (
                            content,
                            attachment.get("name") or f"scorm_{slide_id}.zip",
                            "application/zip",
                        )
                    logger.warning(
                        "[elearning/scorm] Public attachment response was not a "
                        "valid ZIP for slide_id=%s",
                        slide_id,
                    )
                else:
                    logger.warning(
                        "[elearning/scorm] Public attachment request returned "
                        "HTTP %s for slide_id=%s",
                        response.status_code,
                        slide_id,
                    )
        return None