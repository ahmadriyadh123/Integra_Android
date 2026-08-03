from app.core.odoo_client import OdooRPCClient
from typing import List, Dict, Any, Optional

class WeeklyPlanRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def get_weekly_plans(self, uid: int, password: str) -> List[Dict[str, Any]]:
        """
        Record Rule Odoo otomatis memfilter weekly plan 
        sesuai kelas/tingkat siswa yang sedang login.
        """
        fields = [
            'course_id',
            'semester_id',
            'tahun_ajaran_id',
            'pekan',
            'status'
        ]

        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='weekly.plan.sd',
            domain=[('active', '=', True)],
            fields=fields,
            order='id desc'
        )
        return records

    def get_weekly_plan_by_id(self, uid: int, password: str, plan_id: int) -> Optional[Dict[str, Any]]:
        fields = [
            'nama_sekolah', 'alamat_sekolah', 'course_id',
            'semester_id', 'tahun_ajaran_id', 'pekan', 'tema',
            'nama_guru', 'nama_kepsek', 'status'
        ]

        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='weekly.plan.sd',
            domain=[('id', '=', plan_id)],
            fields=fields,
            limit=1
        )
        return records[0] if records else None

    def get_daily_lines(self, uid: int, password: str, model_name: str, plan_id: int) -> List[Dict[str, Any]]:
        """Membaca baris detail harian (misal: weekly.plan.sd.line, weekly.plan.sd.line.selasa, dst)"""
        fields = ['waktu', 'aktivitas', 'media', 'sumber', 'penilaian']
        return self.odoo.search_read(
            uid=uid,
            password=password,
            model=model_name,
            domain=[('weekly_plan_sd_id', '=', plan_id)],
            fields=fields,
            order='id asc'
        )

    def get_tp_lines(self, uid: int, password: str, plan_id: int) -> List[Dict[str, Any]]:
        """Membaca daftar Tujuan Pembelajaran (weekly.plan.sd.line.tp)"""
        fields = ['subject_id', 'tp']
        return self.odoo.search_read(
            uid=uid,
            password=password,
            model='weekly.plan.sd.line.tp',
            domain=[('weekly_plan_sd_id', '=', plan_id)],
            fields=fields,
            order='id asc'
        )