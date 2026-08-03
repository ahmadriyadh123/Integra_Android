from app.core.odoo_client import OdooRPCClient
from typing import List, Dict, Any

class AttendanceRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def get_attendance_history(self, uid: int, password: str, limit: int = 100) -> List[Dict[str, Any]]:
        """
        Panggilan search_read ke Odoo ORM.
        Record Rule Odoo otomatis menyaring data sesuai akun/session uid pengguna yang login!
        """
        fields = [
            'student_id',
            'course_id',
            'batch_id',
            'attendance_date',
            'present',
            'excused',
            'absent',
            'sick',
            'status',
            'remark'
        ]

        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='op.attendance.line',
            domain=[],  # Domain kosong, disaring otomatis oleh Record Rule Odoo
            fields=fields,
            limit=limit,
            order='attendance_date desc, id desc'
        )
        return records