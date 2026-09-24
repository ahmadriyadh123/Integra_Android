from typing import List, Dict, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.core.config import settings

class ElearningRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    def _slide_download_url(
        self, 
        slide_type: Optional[str] = None,
        filename: Optional[str] = None,
        slide_category: Optional[str] = None,
    ) -> Optional[str]:
        """
        Membuat URL akses materi berdasarkan filename yang disimpan Odoo.
        """
        # Path relatif perlu diarahkan ke host Odoo sebelum dikirim ke client.
        if not filename:
            return None
        if filename.startswith('http://') or filename.startswith('https://'):
            return filename
        if filename.startswith('/'):
            return f"{settings.ODOO_URL}{filename}"
        return f"{settings.ODOO_URL}/{filename}"

    async def get_published_courses(self, partner_id: Optional[int] = None) -> List[Dict[str, Any]]:
        """
        Ambil daftar channel/kursus yang dipublikasikan.
        Filter hanya kursus yang user sudah di-enroll via slide_channel_partner jika partner_id ada.
        """
        if partner_id:
            query = text("""
                SELECT 
                    c.id,
                    c.name,
                    c.user_id,
                    p.name AS teacher_name,
                    c.total_slides,
                    c.description,
                    c.is_published
                FROM slide_channel c
                LEFT JOIN res_users u ON u.id = c.user_id
                LEFT JOIN res_partner p ON p.id = u.partner_id
                INNER JOIN slide_channel_partner cp ON cp.channel_id = c.id
                WHERE c.is_published = TRUE
                  AND cp.partner_id = :partner_id
                ORDER BY c.name ASC;
            """)
            result = await self.db.execute(query, {"partner_id": partner_id})
        else:
            query = text("""
                SELECT 
                    c.id,
                    c.name,
                    c.user_id,
                    p.name AS teacher_name,
                    c.total_slides,
                    c.description,
                    c.is_published
                FROM slide_channel c
                LEFT JOIN res_users u ON u.id = c.user_id
                LEFT JOIN res_partner p ON p.id = u.partner_id
                WHERE c.is_published = TRUE
                ORDER BY c.name ASC;
            """)
            result = await self.db.execute(query)

        return [dict(row) for row in result.mappings().all()]

    async def get_course_by_id(self, course_id: int) -> Optional[Dict[str, Any]]:
        """Ambil detail satu channel/kursus berdasarkan ID."""
        query = text("""
            SELECT 
                c.id,
                c.name,
                c.user_id,
                p.name AS teacher_name,
                c.description,
                c.total_slides
            FROM slide_channel c
            LEFT JOIN res_users u ON u.id = c.user_id
            LEFT JOIN res_partner p ON p.id = u.partner_id
            WHERE c.id = :course_id AND c.is_published = TRUE
            LIMIT 1;
        """)

        result = await self.db.execute(query, {"course_id": course_id})
        row = result.mappings().first()
        return dict(row) if row else None

    async def get_slides_by_course_id(self, course_id: int) -> List[Dict[str, Any]]:
        """Ambil daftar slide dalam sebuah channel, lengkap dengan download URL."""
        query = text("""
            SELECT
                s.id,
                s.message_main_attachment_id,
                s.name,
                s.slide_category,
                s.slide_type,
                s.sequence,
                s.is_published,
                s.filename
            FROM slide_slide s
            WHERE s.channel_id = :course_id AND s.is_published = TRUE
            ORDER BY s.sequence ASC, s.id ASC;
        """)
        
        result = await self.db.execute(query, {"course_id": course_id})
        raw_slides = [dict(row) for row in result.mappings().all()]
        for slide in raw_slides:
            slide['download_url'] = self._slide_download_url(
                slide_type=slide.get('slide_type'),
                filename=slide.get('filename'),
                slide_category=slide.get('slide_category'),
            )

        return raw_slides

    async def get_slide_content(self, slide_id: int) -> Optional[Dict[str, Any]]:
        """Ambil sumber konten dari slide_slide untuk endpoint content."""
        query = text("""
            SELECT id, message_main_attachment_id, slide_category, slide_type, filename
            FROM slide_slide
            WHERE id = :slide_id AND is_published = TRUE
            LIMIT 1;
        """)
        result = await self.db.execute(query, {"slide_id": slide_id})
        row = result.mappings().first()
        return dict(row) if row else None

    async def get_attachment(self, attachment_id: int) -> Optional[Dict[str, Any]]:
        """Ambil metadata dan binary attachment Odoo untuk proxy file ke client."""
        query = text("""
            SELECT id, name, store_fname, db_datas, mimetype
            FROM ir_attachment
            WHERE id = :attachment_id
            LIMIT 1;
        """)
        result = await self.db.execute(query, {"attachment_id": attachment_id})
        row = result.mappings().first()
        return dict(row) if row else None

    async def get_scorm_attachment(self, slide_id: int) -> Optional[Dict[str, Any]]:
        """Mencari attachment ZIP SCORM asli berdasarkan tabel relasi ir_attachment_slide_slide_rel."""
        query = text("""
            SELECT ia.id, ia.name, ia.store_fname, ia.db_datas, ia.mimetype, ia.file_size
            FROM ir_attachment_slide_slide_rel rel
            JOIN ir_attachment ia ON rel.ir_attachment_id = ia.id
            WHERE rel.slide_slide_id = :slide_id
              AND (ia.mimetype LIKE '%zip%' OR lower(ia.name) LIKE '%.zip' OR lower(ia.store_fname) LIKE '%.zip')
            ORDER BY ia.id DESC
            LIMIT 1;
        """)
        result = await self.db.execute(query, {"slide_id": slide_id})
        row = result.mappings().first()
        return dict(row) if row else None