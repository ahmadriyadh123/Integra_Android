from app.core.odoo_client import OdooRPCClient
from typing import List, Dict, Any, Optional

class ElearningRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def get_published_courses(self, uid: int, password: str) -> List[Dict[str, Any]]:
        """
        Membaca daftar kursus/mata pelajaran yang dipublikasikan.
        Record Rule Odoo menyaring akses sesuai hak pengguna yang login.
        """
        fields = [
            'name',
            'user_id',
            'total_slides',
            'description',
            'is_published'
        ]

        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='slide.channel',
            domain=[('is_published', '=', True)],
            fields=fields,
            order='name asc'
        )
        return records

    def get_course_by_id(self, uid: int, password: str, course_id: int) -> Optional[Dict[str, Any]]:
        fields = ['name', 'user_id', 'description', 'total_slides']
        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='slide.channel',
            domain=[('id', '=', course_id), ('is_published', '=', True)],
            fields=fields,
            limit=1
        )
        return records[0] if records else None

    def get_slides_by_course_id(self, uid: int, password: str, course_id: int) -> List[Dict[str, Any]]:
        """Membaca daftar slide/materi pembelajaran dalam sebuah channel"""
        fields = [
            'name',
            'slide_category',
            'slide_type',
            'url',
            'sequence',
            'is_published'
        ]

        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='slide.slide',
            domain=[('channel_id', '=', course_id), ('is_published', '=', True)],
            fields=fields,
            order='sequence asc, id asc'
        )
        return records