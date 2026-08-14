# app/features/elearning/repository.py
from typing import List, Dict, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.core.config import settings

class ElearningRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    def _slide_download_url(self, slide_id: int, slide_type: str) -> Optional[str]:
        """
        Buat URL download/akses materi slide dari Odoo/Storage.
        - PDF : /web/content/slide.slide/<id>/slide_datas/materi.pdf
        """
        if slide_type == 'pdf':
            return f"{settings.ODOO_URL}/web/content/slide.slide/{slide_id}/slide_datas/materi.pdf"
        return None

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

    async def get_course_by_id(self, coursec_id: int) -> Optional[Dict[str, Any]]:
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
                id,
                name,
                slide_category,
                slide_type,
                sequence,
                is_published
            FROM slide_slide
            WHERE channel_id = :course_id AND is_published = TRUE
            ORDER BY sequence ASC, id ASC;
        """)
        
        result = await self.db.execute(query, {"course_id": course_id})
        raw_slides = [dict(row) for row in result.mappings().all()]

        # Tambahkan download_url ke setiap slide
        for slide in raw_slides:
            slide['download_url'] = self._slide_download_url(
                slide_id=slide['id'],
                slide_type=str(slide.get('slide_type') or '')
            )

        return raw_slides