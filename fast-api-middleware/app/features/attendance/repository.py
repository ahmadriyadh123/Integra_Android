from app.core.odoo_client import OdooRPCClient
from typing import List, Dict, Any, Optional


class AttendanceRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def get_attendance_history(
        self,
        uid: int,
        password: str,
        student_id: Optional[int] = None,
        limit: int = 100
    ) -> List[Dict[str, Any]]:
        """
        Ambil riwayat presensi dari op.attendance.line.
        """
        fields = [
            'id',
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

        # Jika student_id tidak ada di JWT, kembalikan kosong untuk keamanan
        if student_id is None:
            return []

        # Ambil langsung dengan memfilter student_id di tingkat database Odoo (tanpa sudo)
        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='op.attendance.line',
            domain=[('student_id', '=', student_id)],
            fields=fields,
            limit=limit,
            order='attendance_date desc, id desc'
        )

        return records
