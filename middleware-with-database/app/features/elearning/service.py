import base64
import os
import re
import httpx
from typing import Dict, Any, List, Optional
from pathlib import Path
from app.features.elearning.repository import ElearningRepository
from app.core.config import settings
from sqlalchemy import text

class ScormAccessDeniedError(Exception):
    """SCORM attachment exists but Odoo did not authorize its download."""


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
        """Membaca berkas ZIP SCORM dari db_datas, filestore lokal, atau Odoo Publik."""
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
            clean_store_fname = Path(store_fname)
            base_filestore = Path(settings.ODOO_FILESTORE_PATH)

            possible_paths = [
                base_filestore / clean_store_fname,
                base_filestore / getattr(settings, 'ODOO_DB', '') / clean_store_fname if getattr(settings, 'ODOO_DB', None) else None,
            ]

            for p in possible_paths:
                if p and p.is_file() and p.stat().st_size > 5000:
                    with open(p, "rb") as file:
                        return (
                            file.read(),
                            attachment.get("name") or f"scorm_{slide_id}.zip",
                            "application/zip",
                        )
        # 4. Fallback HTTP Download dari Odoo Publik Menggunakan Session Odoo
        attachment_id = attachment.get("id")
        remote_url = f"{settings.ODOO_URL}/web/content/{attachment_id}?download=true"
        remote_status = None
        
        try:
            async with httpx.AsyncClient(verify=False, follow_redirects=True, timeout=60.0) as client:
                # STEP A: Login singkat ke Odoo Web Controller untuk mendapatkan cookie session_id
                session_id = None
                try:
                    auth_url = f"{settings.ODOO_URL}/web/session/authenticate"
                    auth_body = {
                        "jsonrpc": "2.0",
                        "params": {
                            "db": getattr(settings, 'ODOO_DB', 'kp-sekolah.asetkoptii.com'),
                            "login": getattr(settings, 'ODOO_USER', 'admin'),     # Sesuaikan kredensial di .env
                            "password": getattr(settings, 'ODOO_PASSWORD', 'admin') # Sesuaikan kredensial di .env
                        }
                    }
                    auth_resp = await client.post(auth_url, json=auth_body)
                    session_id = auth_resp.cookies.get("session_id")
                    print(f"[E-LEARNING] Autentikasi Odoo Session Sukses: {session_id[:10] if session_id else 'Gagal'}")
                except Exception as auth_err:
                    print(f"[E-LEARNING] Warning: Gagal autentikasi Odoo Session: {auth_err}")

                # STEP B: Kirimkan Cookie Session Odoo saat mengambil berkas 4.7 MB
                headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
                cookies = {"session_id": session_id} if session_id else {}

                print(f"[E-LEARNING] Mengunduh berkas ZIP SCORM (ID: {attachment_id}) via HTTP Odoo...")
                response = await client.get(remote_url, headers=headers, cookies=cookies)
                remote_status = response.status_code
                
                # STEP C: Validasi file fisik ZIP SCORM asli (harus 200 OK dan > 10 KB)
                if response.status_code == 200 and len(response.content) > 10000:
                    print(f"[E-LEARNING] Berhasil mengunduh ZIP SCORM asli ({len(response.content)} bytes)")
                    return (
                        response.content,
                        attachment.get("name") or f"scorm_{slide_id}.zip",
                        "application/zip",
                    )
                else:
                    print(
                        f"[E-LEARNING] Gagal Unduh HTTP: Status {response.status_code}, "
                        f"Size {len(response.content)} bytes (Kemungkinan terhalang login Odoo)"
                    )
        except Exception as e:
            print(f"[E-LEARNING] Error saat mengunduh ZIP SCORM dari Odoo publik: {e}")

        if remote_status in (401, 403, 404):
            raise ScormAccessDeniedError(
                "Sorry, you are not allowed to access this document."
            )

        return None