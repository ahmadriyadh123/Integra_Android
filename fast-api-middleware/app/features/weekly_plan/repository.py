import logging
import base64
from app.core.odoo_client import OdooRPCClient
from typing import List, Dict, Any, Optional

logger = logging.getLogger(__name__)

# Mapping jenjang ke nama model Odoo (sesuai nama tabel di dump)
JENJANG_MODEL = {
    'sd': 'weekly.plan.sd',
    'smp': 'weekly.plan.smp',
    'tk': 'weekly.plan',
}

HARI_MODEL_SUFFIX = {
    'senin':  'line',
    'selasa': 'line.selasa',
    'rabu':   'line.rabu',
    'kamis':  'line.kamis',
    'jumat':  'line.jumat',
}


class WeeklyPlanRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def _base_model(self, jenjang: str) -> str:
        key = (jenjang or 'sd').lower()
        return JENJANG_MODEL.get(key, 'weekly.plan.sd')

    def get_weekly_plans(
        self, uid: int, password: str, jenjang: str = 'sd',
        course_id: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        """
        Ambil daftar weekly plan menggunakan kredensial user portal.
        Jika tidak ditemukan di jenjang yang diminta, coba jenjang lainnya sebagai fallback.
        """
        fields = [
            'id', 'course_id', 'semester_id', 'tahun_ajaran_id',
            'pekan', 'status', 'tema', 'nama_guru'
        ]
        primary_model = self._base_model(jenjang)
        models_to_try = [primary_model] + [
            m for m in JENJANG_MODEL.values() if m != primary_model
        ]

        for model in models_to_try:
            try:
                records = self.odoo.search_read(
                    uid=uid, password=password,
                    model=model,
                    domain=[('active', '=', True)],
                    fields=fields,
                    order='id desc'
                )

                if course_id is not None and records:
                    filtered = []
                    for r in records:
                        cid = r.get('course_id')
                        record_course_id = cid[0] if isinstance(cid, list) else cid
                        if record_course_id == course_id:
                            filtered.append(r)
                    if filtered:
                        return filtered
                elif records:
                    return records
            except Exception as e:
                logger.warning(f"[weekly_plan repo] Failed search_read model={model}: {e}")

        return []

    def get_weekly_plan_by_id(
        self, uid: int, password: str,
        plan_id: int, jenjang: str = 'sd'
    ) -> Optional[Dict[str, Any]]:
        fields = [
            'id', 'nama_sekolah', 'alamat_sekolah', 'course_id',
            'semester_id', 'tahun_ajaran_id', 'pekan', 'tema',
            'nama_guru', 'nama_kepsek', 'status',
            'senin', 'selasa', 'rabu', 'kamis', 'jumat',
            'message_main_attachment_id'
        ]
        primary_model = self._base_model(jenjang)
        models_to_try = [primary_model] + [
            m for m in JENJANG_MODEL.values() if m != primary_model
        ]

        for model in models_to_try:
            try:
                records = self.odoo.search_read(
                    uid=uid, password=password,
                    model=model,
                    domain=[('id', '=', plan_id)],
                    fields=fields,
                    limit=1
                )
                if records:
                    res = records[0]
                    res['_resolved_model'] = model
                    return res
            except Exception as e:
                logger.warning(f"[weekly_plan repo] Failed detail model={model} id={plan_id}: {e}")

        return None

    def get_attachment_pdf(
        self, uid: int, password: str,
        attachment_id: int
    ) -> Optional[bytes]:
        """
        Fetch binary PDF dari ir.attachment berdasarkan ID.
        Field 'datas' berisi konten file dalam format base64.
        """
        try:
            records = self.odoo.search_read(
                uid=uid, password=password,
                model='ir.attachment',
                domain=[('id', '=', attachment_id)],
                fields=['id', 'name', 'mimetype', 'datas'],
                limit=1
            )
            if not records:
                return None

            attachment = records[0]
            datas = attachment.get('datas')
            if not datas or datas is False:
                return None

            return base64.b64decode(datas)
        except Exception as e:
            logger.warning(f"[weekly_plan] gagal fetch attachment id={attachment_id}: {e}")
            return None

    def get_daily_lines(
        self, uid: int, password: str,
        plan_id: int, hari: str, jenjang: str = 'sd',
        resolved_model: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        suffix = HARI_MODEL_SUFFIX.get(hari, 'line')
        base = resolved_model or self._base_model(jenjang)
        model = f'{base}.{suffix}'
        fields = ['id', 'waktu', 'aktivitas', 'media', 'sumber', 'penilaian']
        try:
            return self.odoo.search_read(
                uid=uid, password=password,
                model=model,
                domain=[('weekly_plan_id', '=', plan_id)],
                fields=fields,
                order='id asc'
            )
        except Exception as e:
            # Jika terjadi error otorisasi/Access Error dari Odoo, 
            # tangkap eksepsi dan kembalikan list kosong agar tidak memutus aliran data.
            logger.warning(f"[weekly_plan] Otorisasi gagal / error ambil line {hari} model={model}: {e}")
            return []

    def get_tp_lines(
        self, uid: int, password: str,
        plan_id: int, jenjang: str = 'sd',
        resolved_model: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        base = resolved_model or self._base_model(jenjang)
        model = f'{base}.line.tp'
        fields = ['id', 'subject_id', 'tp']
        try:
            return self.odoo.search_read(
                uid=uid, password=password,
                model=model,
                domain=[('weekly_plan_id', '=', plan_id)],
                fields=fields,
                order='id asc'
            )
        except Exception as e:
            # Jika terjadi error otorisasi/Access Error dari Odoo,
            # tangkap eksepsi dan kembalikan list kosong agar tidak memutus aliran data.
            logger.warning(f"[weekly_plan] Otorisasi gagal / error ambil tp lines model={model}: {e}")
            return []

    def get_tp_lines(
        self, uid: int, password: str,
        plan_id: int, jenjang: str = 'sd',
        resolved_model: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        base = resolved_model or self._base_model(jenjang)
        model = f'{base}.line.tp'
        fields = ['id', 'subject_id', 'tp']
        try:
            return self.odoo.search_read(
                uid=uid, password=password,
                model=model,
                domain=[('weekly_plan_id', '=', plan_id)],
                fields=fields,
                order='id asc'
            )
        except Exception as e:
            # Tangkap error hak akses dan kembalikan list kosong
            logger.warning(f"[weekly_plan] gagal ambil tp lines model={model}: {e}")
            return []

    def get_attachment_image_base64(
        self, uid: int, password: str,
        res_model: str, res_id: int, res_field: str
    ) -> Optional[str]:
        """Mengambil file gambar TTD dari ir.attachment berdasarkan res_model & res_field via RPC."""
        try:
            records = self.odoo.search_read(
                uid=uid, password=password,
                model='ir.attachment',
                domain=[
                    ('res_model', 'in', [res_model, 'weekly.plan.sd', 'weekly.plan.smp', 'weekly.plan']),
                    ('res_id', '=', res_id),
                    ('res_field', '=', res_field)
                ],
                fields=['id', 'datas'],
                limit=1
            )
            if records and records[0].get('datas'):
                return records[0]['datas']
            return None
        except Exception as e:
            logger.warning(f"[weekly_plan] gagal fetch image base64 {res_field}: {e}")
            return None

    def get_logo_base64(
        self, uid: int, password: str
    ) -> Optional[str]:
        """Mengambil logo lembaga dari ir.attachment via RPC."""
        try:
            records = self.odoo.search_read(
                uid=uid, password=password,
                model='ir.attachment',
                domain=['|', ('name', 'ilike', 'logo'), ('id', '=', 588)],
                fields=['id', 'datas'],
                limit=1
            )
            if records and records[0].get('datas'):
                return records[0]['datas']
            return None
        except Exception as e:
            logger.warning(f"[weekly_plan] gagal fetch logo: {e}")
            return None


