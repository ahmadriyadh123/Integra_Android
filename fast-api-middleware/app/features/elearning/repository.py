import logging
import xmlrpc.client
from app.core.odoo_client import OdooRPCClient
from typing import List, Dict, Any, Optional

logger = logging.getLogger(__name__)


class ElearningRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def _search_all(
        self,
        uid: int,
        password: str,
        model: str,
        domain: list,
        fields: list,
        order: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        page_size = 80
        offset = 0
        records: List[Dict[str, Any]] = []
        while True:
            page = self.odoo.search_read(
                uid=uid,
                password=password,
                model=model,
                domain=domain,
                fields=fields,
                limit=page_size,
                order=order,
                offset=offset,
            )
            records.extend(page)
            if len(page) < page_size:
                return records
            offset += len(page)

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

    def _odoo_url(self, value: Optional[str]) -> Optional[str]:
        if not value:
            return None
        if value.startswith('http://') or value.startswith('https://'):
            return value
        if value.startswith('/'):
            return f"{self.odoo.url}{value}"
        return f"{self.odoo.url}/{value}"

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

        domain = [('is_published', '=', True)]

        return self._search_all(
            uid=uid,
            password=password,
            model='slide.channel',
            domain=domain,
            fields=fields,
            order='name asc, id asc',
        )

    def get_course_sync_changes(
        self,
        uid: int,
        password: str,
        partner_id: Optional[int],
        modified_after: str,
    ) -> tuple[List[Dict[str, Any]], List[int]]:
        modified_domain = [('write_date', '>=', modified_after)]
        changed_channels = self._search_all(
            uid=uid,
            password=password,
            model='slide.channel',
            domain=modified_domain,
            fields=['id'],
            order='id asc',
        )
        course_ids = {
            int(record['id'])
            for record in changed_channels
            if record.get('id')
        }

        changed_slides = self._search_all(
            uid=uid,
            password=password,
            model='slide.slide',
            domain=modified_domain,
            fields=['id', 'channel_id'],
            order='id asc',
        )
        slide_ids = {
            int(record['id'])
            for record in changed_slides
            if record.get('id')
        }
        course_ids.update(
            int(channel[0])
            for record in changed_slides
            if isinstance((channel := record.get('channel_id')), (list, tuple))
            and channel
        )

        if partner_id is not None:
            changed_progress = self._search_all(
                uid=uid,
                password=password,
                model='slide.slide.partner',
                domain=[
                    ('partner_id', '=', partner_id),
                    *modified_domain,
                ],
                fields=['slide_id'],
                order='id asc',
            )
            slide_ids.update(
                int(slide[0])
                for record in changed_progress
                if isinstance((slide := record.get('slide_id')), (list, tuple))
                and slide
            )

        if slide_ids:
            related_slides = self._search_all(
                uid=uid,
                password=password,
                model='slide.slide',
                domain=[('id', 'in', sorted(slide_ids))],
                fields=['channel_id'],
                order='id asc',
            )
            course_ids.update(
                int(channel[0])
                for record in related_slides
                if isinstance((channel := record.get('channel_id')), (list, tuple))
                and channel
            )

        if not course_ids:
            return [], []

        channels = self._search_all(
            uid=uid,
            password=password,
            model='slide.channel',
            domain=[('id', 'in', sorted(course_ids))],
            fields=[
                'id',
                'name',
                'user_id',
                'total_slides',
                'description',
                'is_published',
            ],
            order='id asc',
        )
        published = [course for course in channels if course.get('is_published')]
        removed_ids = [
            int(course['id'])
            for course in channels
            if course.get('id') and not course.get('is_published')
        ]
        return published, removed_ids

    def get_progress_by_course(
        self,
        uid: int,
        password: str,
        partner_id: int,
    ) -> Dict[int, set[int]]:
        completed_records = self._search_all(
            uid=uid,
            password=password,
            model='slide.slide.partner',
            domain=[
                ('partner_id', '=', partner_id),
                ('completed', '=', True),
            ],
            fields=['slide_id'],
        )
        slide_ids = [
            record['slide_id'][0]
            for record in completed_records
            if isinstance(record.get('slide_id'), (list, tuple))
            and record['slide_id']
        ]
        if not slide_ids:
            return {}

        slides = self._search_all(
            uid=uid,
            password=password,
            model='slide.slide',
            domain=[
                ('id', 'in', slide_ids),
                ('is_published', '=', True),
            ],
            fields=['id', 'channel_id'],
        )
        progress: Dict[int, set[int]] = {}
        for slide in slides:
            channel = slide.get('channel_id')
            if isinstance(channel, (list, tuple)) and channel:
                progress.setdefault(int(channel[0]), set()).add(int(slide['id']))
        return progress

    def get_completed_slide_ids(
        self,
        uid: int,
        password: str,
        course_id: int,
        partner_id: int,
    ) -> set[int]:
        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='slide.slide.partner',
            domain=[
                ('partner_id', '=', partner_id),
                ('slide_id.channel_id', '=', course_id),
                ('completed', '=', True),
            ],
            fields=['slide_id'],
        )
        return {
            int(record['slide_id'][0])
            for record in records
            if isinstance(record.get('slide_id'), (list, tuple))
            and record['slide_id']
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
        slides = self.odoo.search_read(
            uid=uid,
            password=password,
            model='slide.slide',
            domain=[
                ('id', '=', slide_id),
                ('channel_id', '=', course_id),
                ('is_published', '=', True),
            ],
            fields=['id', 'slide_category', 'slide_type'],
            limit=1,
        )
        if not slides:
            return False

        slide = slides[0]
        is_scorm = (
            str(slide.get('slide_type') or '').lower() == 'scorm'
            or str(slide.get('slide_category') or '').lower() == 'scorm'
        )
        slide_types = {
            str(slide.get('slide_type') or '').lower(),
            str(slide.get('slide_category') or '').lower(),
        }
        is_quiz = bool(slide_types & {'quiz', 'question'})
        if source == 'opened' and (is_scorm or is_quiz):
            return False
        if source == 'scorm' and (
            not is_scorm
            or (completion_status or '').lower() not in {'completed', 'passed'}
        ):
            return False
        if source not in {'opened', 'scorm'}:
            return False

        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='slide.slide.partner',
            domain=[
                ('slide_id', '=', slide_id),
                ('partner_id', '=', partner_id),
            ],
            fields=['id', 'completed'],
            limit=1,
        )
        if records:
            record = records[0]
            if record.get('completed'):
                return True
            return bool(
                self.odoo.execute_kw(
                    uid=uid,
                    password=password,
                    model='slide.slide.partner',
                    method='write',
                    args=[[record['id']], {'completed': True}],
                )
            )

        return bool(
            self.odoo.execute_kw(
                uid=uid,
                password=password,
                model='slide.slide.partner',
                method='create',
                args=[{
                    'slide_id': slide_id,
                    'partner_id': partner_id,
                    'completed': True,
                }],
            )
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

    def get_course_messages(
        self,
        uid: int,
        password: str,
        course_id: int,
        limit: int = 100,
    ) -> Optional[List[Dict[str, Any]]]:
        if not self.get_course_by_id(uid, password, course_id):
            return None

        return self.odoo.search_read(
            uid=uid,
            password=password,
            model='mail.message',
            domain=[
                ('model', '=', 'slide.channel'),
                ('res_id', '=', course_id),
                ('message_type', '=', 'comment'),
            ],
            fields=['id', 'author_id', 'body', 'date'],
            limit=limit,
            order='date desc, id desc',
        )

    def post_course_message(
        self,
        uid: int,
        password: str,
        course_id: int,
        body: str,
    ) -> Optional[int]:
        if not self.get_course_by_id(uid, password, course_id):
            return None

        message_id = self.odoo.execute_kw(
            uid=uid,
            password=password,
            model='slide.channel',
            method='message_post',
            args=[[course_id]],
            kwargs={
                'body': body,
                'message_type': 'comment',
                'subtype_xmlid': 'mail.mt_comment',
            },
        )
        return int(message_id)

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
        fields = ['id', 'name', 'datas', 'mimetype']
        logger.info(
            "[elearning/scorm] RPC lookup started db=%s uid=%s slide_id=%s "
            "model=ir.attachment method=search_read fields=%s",
            self.odoo.db,
            uid,
            slide_id,
            fields,
        )
        try:
            records = self.odoo.search_read(
                uid=uid,
                password=password,
                model='ir.attachment',
                domain=[
                    ('res_model', '=', 'slide.slide'),
                    ('res_id', '=', slide_id)
                ],
                fields=fields,
                limit=1,
            )
        except xmlrpc.client.Fault as exc:
            logger.error(
                "[elearning/scorm] RPC fault db=%s uid=%s slide_id=%s "
                "model=ir.attachment method=search_read fault_code=%s fault=%s",
                self.odoo.db,
                uid,
                slide_id,
                exc.faultCode,
                exc.faultString,
            )
            raise

        logger.info(
            "[elearning/scorm] RPC lookup completed db=%s uid=%s slide_id=%s "
            "attachment_count=%s",
            self.odoo.db,
            uid,
            slide_id,
            len(records),
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
