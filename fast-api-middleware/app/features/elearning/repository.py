from app.core.odoo_client import OdooRPCClient
from app.core.config import settings
from typing import List, Dict, Any, Optional


class ElearningRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def _slide_download_url(self, slide_id: int, slide_type: str) -> Optional[str]:
        """
        Buat URL download/akses materi slide dari Odoo.
        - PDF    : /web/content/slide.slide/<id>/slide_datas/<name>.pdf
        - SCORM  : tidak ada URL langsung, dikembalikan None
        """
        if slide_type == 'pdf':
            return f"{settings.ODOO_URL}/web/content/slide.slide/{slide_id}/slide_datas/materi.pdf"
        return None

    def get_published_courses(self, uid: int, password: str) -> List[Dict[str, Any]]:
        """Ambil daftar channel/kursus yang dipublikasikan."""
        fields = [
            'id',
            'name',
            'user_id',
            'total_slides',
            'description',
            'is_published',
        ]
        return self.odoo.search_read(
            uid=uid,
            password=password,
            model='slide.channel',
            domain=[('is_published', '=', True)],
            fields=fields,
            order='name asc'
        )

    def get_course_by_id(self, uid: int, password: str, course_id: int) -> Optional[Dict[str, Any]]:
        """Ambil detail satu channel/kursus berdasarkan ID."""
        fields = ['id', 'name', 'user_id', 'description', 'total_slides']
        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='slide.channel',
            domain=[('id', '=', course_id), ('is_published', '=', True)],
            fields=fields,
            limit=1
        )
        return records[0] if records else None

    def get_slides_by_course_id(
        self, uid: int, password: str, course_id: int
    ) -> List[Dict[str, Any]]:
        """
        Ambil daftar slide dalam sebuah channel, lengkap dengan download URL.
        url dikosongkan dari Odoo (selalu False), sehingga dibangun di sini.
        """
        fields = [
            'id',
            'name',
            'slide_category',
            'slide_type',
            'sequence',
            'is_published',
        ]
        raw = self.odoo.search_read(
            uid=uid,
            password=password,
            model='slide.slide',
            domain=[('channel_id', '=', course_id), ('is_published', '=', True)],
            fields=fields,
            order='sequence asc, id asc'
        )

        # Tambahkan download_url ke setiap slide
        for slide in raw:
            slide['download_url'] = self._slide_download_url(
                slide_id=slide['id'],
                slide_type=str(slide.get('slide_type') or '')
            )

        return raw
