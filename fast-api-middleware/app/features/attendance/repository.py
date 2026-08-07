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

        Filter menggunakan student_id (integer) yang sudah diperoleh saat login
        dan disimpan di JWT — tidak ada dot-notation, tidak ada traverse ke
        op.student, sehingga tidak memerlukan akses ke model tersebut.
        """
        fields = [
            'id',
            # 'student_id',
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

        # Filter langsung dengan integer student_id — tidak ada join ke op.student
        domain = [('student_id', '=', student_id)] if student_id else []

        return self.odoo.search_read(
            uid=uid,
            password=password,
            model='op.attendance.line',
            domain=domain,
            fields=fields,
            limit=limit,
            order='attendance_date desc, id desc'
        )
