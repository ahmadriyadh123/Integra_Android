import logging
import base64
from app.core.odoo_client import OdooRPCClient
from typing import List, Dict, Any, Optional

logger = logging.getLogger(__name__)

# Mapping jenjang ke nama model Odoo (sesuai nama tabel di dump: weekly_plan_sd)
JENJANG_MODEL = {
    'sd': 'weekly.plan.sd',
    'smp': 'weekly.plan.smp',
    'tk': 'weekly.plan',
}

# Model line per hari (sesuai nama tabel: weekly_plan_line, weekly_plan_line_selasa, dst.)
# Senin menggunakan weekly.plan.{jenjang}.line (tabel: weekly_plan_line / weekly_plan_sd_line)
# Hari lain menggunakan weekly.plan.{jenjang}.line.{hari}
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
        return JENJANG_MODEL.get(jenjang, 'weekly.plan.sd')

    def get_weekly_plans(
        self, uid: int, password: str, jenjang: str = 'sd',
        course_id: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        """
        Ambil daftar weekly plan. Gunakan sudo agar user portal bisa akses,
        lalu filter manual berdasarkan course_id jika tersedia.
        """
        fields = [
            'id', 'course_id', 'semester_id', 'tahun_ajaran_id',
            'pekan', 'status', 'tema', 'nama_guru'
        ]
        model = self._base_model(jenjang)
        domain = [('active', '=', True)]

        records = self.odoo.search_read(
            uid=uid, password=password,
            model=model,
            domain=domain,
            fields=fields,
            order='id desc',
            use_sudo=True
        )

        # Filter manual berdasarkan course_id jika tersedia
        if course_id is not None:
            filtered = []
            for r in records:
                cid = r.get('course_id')
                record_course_id = cid[0] if isinstance(cid, list) else cid
                if record_course_id == course_id:
                    filtered.append(r)
            return filtered

        return records

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
        model = self._base_model(jenjang)

        records = self.odoo.search_read(
            uid=uid, password=password,
            model=model,
            domain=[('id', '=', plan_id)],
            fields=fields,
            limit=1,
            use_sudo=True
        )
        return records[0] if records else None

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
                limit=1,
                use_sudo=True
            )
            if not records:
                return None

            attachment = records[0]
            datas = attachment.get('datas')
            if not datas or datas is False:
                return None

            # datas dari Odoo adalah string base64
            return base64.b64decode(datas)
        except Exception as e:
            logger.warning(f"[weekly_plan] gagal fetch attachment id={attachment_id}: {e}")
            return None

    def get_daily_lines(
        self, uid: int, password: str,
        plan_id: int, hari: str, jenjang: str = 'sd'
    ) -> List[Dict[str, Any]]:
        """
        Ambil baris kegiatan harian dari model line per hari.
        Nama model: weekly.plan.sd.line (senin), weekly.plan.sd.line.selasa, dst.
        Field relasi di semua tabel line: weekly_plan_id
        """
        suffix = HARI_MODEL_SUFFIX.get(hari, 'line')
        base = self._base_model(jenjang)
        model = f'{base}.{suffix}'

        fields = ['id', 'waktu', 'aktivitas', 'media', 'sumber', 'penilaian']

        try:
            return self.odoo.search_read(
                uid=uid, password=password,
                model=model,
                domain=[('weekly_plan_id', '=', plan_id)],
                fields=fields,
                order='id asc',
                use_sudo=True
            )
        except Exception as e:
            logger.warning(f"[weekly_plan] gagal ambil line {hari} model={model}: {e}")
            return []

    def get_tp_lines(
        self, uid: int, password: str,
        plan_id: int, jenjang: str = 'sd'
    ) -> List[Dict[str, Any]]:
        """
        Ambil Tujuan Pembelajaran dari weekly.plan.sd.line.tp
        Field relasi: weekly_plan_id
        """
        base = self._base_model(jenjang)
        model = f'{base}.line.tp'
        fields = ['id', 'subject_id', 'tp']

        try:
            return self.odoo.search_read(
                uid=uid, password=password,
                model=model,
                domain=[('weekly_plan_id', '=', plan_id)],
                fields=fields,
                order='id asc',
                use_sudo=True
            )
        except Exception as e:
            logger.warning(f"[weekly_plan] gagal ambil tp lines model={model}: {e}")
            return []
