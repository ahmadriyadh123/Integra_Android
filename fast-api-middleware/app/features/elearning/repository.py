from app.core.odoo_client import OdooRPCClient
from app.core.config import settings
from typing import List, Dict, Any, Optional


class ElearningRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def _slide_download_url(
        self,
        slide_type: Optional[str],
        filename: Optional[str],
        slide_category: Optional[str] = None,
    ) -> Optional[str]:
        material_type = (slide_type or '').lower()
        category = (slide_category or '').lower()

        # SCORM:
        # website_scorm_elearning sudah mengekstrak ZIP
        # dan filename menunjuk langsung ke index.html.
        if material_type == 'scorm' or category == 'scorm':
            return self._odoo_url(filename)

        return self._odoo_url(filename)

    @staticmethod
    def _odoo_url(value: Optional[str]) -> Optional[str]:
        if not value:
            return None
        if value.startswith('http://') or value.startswith('https://'):
            return value
        if value.startswith('/'):
            return f"{settings.ODOO_URL}{value}"
        return f"{settings.ODOO_URL}/{value}"

    def get_published_courses(
        self,
        uid: int,
        password: str,
        partner_id: Optional[int] = None
    ) -> List[Dict[str, Any]]:

        fields = [
            'id',
            'name',
            'user_id',
            'total_slides',
            'description',
            'is_published',
        ]

        # Jangan memfilter melalui channel_partner_ids. Relasi tersebut
        # memicu ACL slide.channel.partner untuk user portal biasa.
        domain = [('is_published', '=', True)]

        return self.odoo.search_read(
            uid=uid,
            password=password,
            model='slide.channel',
            domain=domain,
            fields=fields,
            order='name asc'
        )

    def get_course_by_id(
        self,
        uid: int,
        password: str,
        course_id: int
    ) -> Optional[Dict[str, Any]]:

        fields = [
            'id',
            'name',
            'user_id',
            'description',
            'total_slides'
        ]

        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='slide.channel',
            domain=[
                ('id', '=', course_id),
                ('is_published', '=', True)
            ],
            fields=fields,
            limit=1
        )

        return records[0] if records else None

    def get_slides_by_course_id(
        self,
        uid: int,
        password: str,
        course_id: int
    ) -> List[Dict[str, Any]]:

        fields = [
            'id',
            'name',
            'slide_category',
            'slide_type',
            'sequence',
            'is_published',
            'filename',
        ]

        raw = self.odoo.search_read(
            uid=uid,
            password=password,
            model='slide.slide',
            domain=[
                ('channel_id', '=', course_id),
                ('is_published', '=', True)
            ],
            fields=fields,
            order='sequence asc, id asc'
        )

        for slide in raw:
            slide['download_url'] = self._slide_download_url(
                slide_type=slide.get('slide_type'),
                filename=slide.get('filename'),
                slide_category=slide.get('slide_category'),
            )
            
        return raw

    def get_slide_content(
        self,
        uid: int,
        password: str,
        slide_id: int
    ) -> Optional[Dict[str, Any]]:
        """Ambil sumber konten dari slide.slide untuk endpoint content."""
        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='slide.slide',
            domain=[('id', '=', slide_id), ('is_published', '=', True)],
            fields=['id', 'slide_category', 'slide_type', 'filename'],
            limit=1
        )
        return records[0] if records else None

    def get_scorm_attachment(
        self,
        uid: int,
        password: str,
        slide_id: int
    ) -> Optional[Dict[str, Any]]:
        """Ambil attachment SCORM dari ir.attachment via Odoo RPC."""
        import base64
        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='ir.attachment',
            domain=[
                ('res_model', 'in', ['slide.slide', 'slide.channel.slide']),
                ('res_id', '=', slide_id)
            ],
            fields=['id', 'name', 'datas', 'mimetype'],
            limit=1
        )
        if records and records[0].get('datas'):
            raw = records[0]
            name = raw.get('name') or f"scorm_{slide_id}.zip"
            mimetype = raw.get('mimetype') or 'application/zip'
            content = base64.b64decode(raw['datas'])
            return {
                'content': content,
                'filename': name,
                'mimetype': mimetype
            }
        return None


