from app.core.odoo_client import OdooRPCClient
from typing import List, Dict, Any, Optional

class ERaporRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def get_student_reports(self, uid: int, password: str) -> List[Dict[str, Any]]:
        """Mengambil daftar e-rapor siswa per semester"""
        fields = [
            'student_id', 'kelas_id', 'semester_id', 
            'tahun_ajaran_id', 'rata_rata_nilai', 
            'catatan_wali_kelas', 'status_keputusan', 'file_rapor_pdf'
        ]

        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='grading.assignment', # Atau model e-rapor spesifik modul sekolah Anda
            domain=[],
            fields=fields,
            order='id desc'
        )
        return records

    def get_report_card_details(self, uid: int, password: str, rapor_id: int) -> Optional[Dict[str, Any]]:
        """Mengambil detail nilai per mata pelajaran"""
        reports = self.odoo.search_read(
            uid=uid,
            password=password,
            model='grading.assignment',
            domain=[('id', '=', rapor_id)],
            fields=['student_id', 'kelas_id', 'rata_rata_nilai', 'catatan_wali_kelas'],
            limit=1
        )
        if not reports:
            return None

        report = reports[0]

        # Ambil rincian nilai mata pelajaran (KI-3 Pengetahuan & KI-4 Keterampilan)
        lines = self.odoo.search_read(
            uid=uid,
            password=password,
            model='grading.assignment.line',
            domain=[('assignment_id', '=', rapor_id)],
            fields=['subject_id', 'nilai_pengetahuan', 'nilai_keterampilan', 'predikat']
        )
        
        report['subjects'] = lines
        return report