# app/features/elearning/repository.py
from typing import List, Dict, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.core.config import settings

class ElearningRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    def _slide_download_url(
        self, 
        slide_id: int, 
        slide_type: str, 
        slide_category: str = '',
        attachment_id: Optional[int] = None,
        attachment_name: Optional[str] = None
    ) -> Optional[str]:
        """
        Buat URL download/akses materi slide via Proxy Middleware REST API.
        Memastikan klien mobile dapat mengunduh berkas tanpa terhalang firewall port 8069.
        """
        if attachment_id and attachment_name:
            return f"/api/v1/elearning/content/{attachment_id}/{attachment_name}"
        return f"/api/v1/elearning/content/slide/{slide_id}"

    async def get_attachment_by_id(self, attachment_id: int) -> Optional[Dict[str, Any]]:
        """Ambil metadata attachment dari tabel ir_attachment."""
        query = text("""
            SELECT id, name, mimetype, store_fname, db_datas
            FROM ir_attachment
            WHERE id = :id
            LIMIT 1;
        """)
        result = await self.db.execute(query, {"id": attachment_id})
        row = result.mappings().first()
        return dict(row) if row else None

    async def get_published_courses(self, partner_id: Optional[int] = None) -> List[Dict[str, Any]]:
        """
        Ambil daftar channel/kursus yang dipublikasikan.
        Filter hanya kursus yang user sudah di-enroll via slide_channel_partner.
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
            SELECT DISTINCT ON (s.id)
                s.id,
                s.name,
                s.slide_category,
                s.slide_type,
                s.sequence,
                s.is_published,
                a.id AS attachment_id,
                a.name AS attachment_name
            FROM slide_slide s
            LEFT JOIN ir_attachment a ON (
                a.res_model = 'slide.slide' 
                AND a.res_id = s.id 
                AND (a.mimetype = 'application/zip' OR a.name ILIKE '%.zip')
            )
            WHERE s.channel_id = :course_id AND s.is_published = TRUE
            ORDER BY s.id ASC, a.id DESC;
        """)
        
        result = await self.db.execute(query, {"course_id": course_id})
        raw_slides = [dict(row) for row in result.mappings().all()]
        raw_slides.sort(key=lambda x: (x.get('sequence') or 0, x['id']))

        # Tambahkan download_url ke setiap slide
        for slide in raw_slides:
            slide['download_url'] = self._slide_download_url(
                slide_id=slide['id'],
                slide_type=str(slide.get('slide_type') or ''),
                slide_category=str(slide.get('slide_category') or ''),
                attachment_id=slide.get('attachment_id'),
                attachment_name=slide.get('attachment_name')
            )

        return raw_slides