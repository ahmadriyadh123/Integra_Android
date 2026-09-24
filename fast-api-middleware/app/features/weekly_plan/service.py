import html
import logging
import re
from typing import Dict, Any, List, Optional
from app.features.weekly_plan.repository import WeeklyPlanRepository

logger = logging.getLogger(__name__)


class WeeklyPlanService:
    def __init__(self, repo: WeeklyPlanRepository):
        self.repo = repo

    def _clean_html(self, val: Any, fallback: str = '-') -> str:
        if val is None or val is False:
            return fallback
        text = str(val)
        # Strip tag HTML seperti <p>, </p>, <br>, dll.
        text = re.sub(r'<[^>]+>', '', text)
        # Unescape entitas HTML seperti &nbsp; dan &amp;
        text = html.unescape(text)
        text = text.strip()
        return text if text else fallback

    def _parse_many2one(self, val: Any, fallback: str = '-') -> str:
        if isinstance(val, list) and len(val) > 1:
            return self._clean_html(val[1], fallback)
        if isinstance(val, str):
            return self._clean_html(val, fallback)
        return fallback

    def _str(self, val: Any, fallback: str = '-') -> str:
        if val and val is not False:
            return self._clean_html(val, fallback)
        return fallback

    def _clean_daily_lines(self, raw: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        return [
            {
                "id": r.get("id"),
                "waktu": self._str(r.get("waktu")),
                "aktivitas": self._str(r.get("aktivitas")),
                "media": self._str(r.get("media")),
                "sumber": self._str(r.get("sumber")),
                "penilaian": self._str(r.get("penilaian")),
            }
            for r in raw
        ]

    def get_weekly_plan_list(
        self, uid: int, password: str,
        jenjang: str = 'sd',
        course_id: Optional[int] = None
    ) -> Dict[str, Any]:
        raw = self.repo.get_weekly_plans(
            uid=uid, password=password,
            jenjang=jenjang, course_id=course_id
        )

        weekly_plans = []
        for p in raw:
            weekly_plans.append({
                "id": p.get("id"),
                "kelas": self._parse_many2one(p.get("course_id"), "-"),
                "semester": self._parse_many2one(p.get("semester_id"), "-"),
                "tahun_ajaran": self._parse_many2one(p.get("tahun_ajaran_id"), "-"),
                "pekan": self._str(p.get("pekan")),
                "tema": self._str(p.get("tema")),
                "nama_guru": self._str(p.get("nama_guru")),
                "status": self._str(p.get("status"), "draft"),
            })

        return {
            "total_records": len(weekly_plans),
            "weekly_plans": weekly_plans
        }

    def get_weekly_plan_detail(
        self, uid: int, password: str,
        plan_id: int, jenjang: str = 'sd'
    ) -> Optional[Dict[str, Any]]:
        header = self.repo.get_weekly_plan_by_id(
            uid=uid, password=password,
            plan_id=plan_id, jenjang=jenjang
        )
        if not header:
            return None

        resolved_model = header.get('_resolved_model')

        # 1. Tujuan Pembelajaran
        raw_tp = self.repo.get_tp_lines(
            uid=uid, password=password,
            plan_id=plan_id, jenjang=jenjang,
            resolved_model=resolved_model
        )
        tp_list = [
            {
                "id": tp.get("id"),
                "subject_name": self._parse_many2one(tp.get("subject_id"), "Mata Pelajaran"),
                "tp": self._str(tp.get("tp")),
            }
            for tp in raw_tp
        ]

        # 2. Rincian Kegiatan Harian
        days = ['senin', 'selasa', 'rabu', 'kamis', 'jumat']
        daily = {}
        for hari in days:
            raw_lines = self.repo.get_daily_lines(
                uid=uid, password=password,
                plan_id=plan_id, hari=hari, jenjang=jenjang,
                resolved_model=resolved_model
            )
            daily[hari] = self._clean_daily_lines(raw_lines)

        # 3. Format Tanggal
        from datetime import datetime
        write_date = header.get("write_date")
        if write_date:
            try:
                date_obj = datetime.strptime(str(write_date)[:10], "%Y-%m-%d")
                formatted_date = date_obj.strftime("%d %B %Y")
            except Exception:
                formatted_date = datetime.now().strftime("%d %B %Y")
        else:
            formatted_date = datetime.now().strftime("%d %B %Y")

        return {
            "id": header.get("id"),
            "jenjang": jenjang.upper(),
            "nama_sekolah": self._str(header.get("nama_sekolah"), "ERP Integra Edusolusi"),
            "alamat_sekolah": self._str(header.get("alamat_sekolah"), "Jl. Pena Kencana BSD"),
            "kelas": self._parse_many2one(header.get("course_id"), "-"),
            "semester": self._parse_many2one(header.get("semester_id"), "-"),
            "tahun_ajaran": self._parse_many2one(header.get("tahun_ajaran_id"), "-"),
            "pekan": self._str(header.get("pekan")),
            "tema": self._str(header.get("tema")),
            "nama_guru": self._str(header.get("nama_guru")),
            "nama_kepsek": self._str(header.get("nama_kepsek")),
            "status": self._str(header.get("status"), "draft"),
            "write_date": formatted_date,
            "tujuan_pembelajaran": tp_list,
            "senin": self._str(header.get("senin"), "-"),
            "selasa": self._str(header.get("selasa"), "-"),
            "rabu": self._str(header.get("rabu"), "-"),
            "kamis": self._str(header.get("kamis"), "-"),
            "jumat": self._str(header.get("jumat"), "-"),
            # List kegiatan harian yang akan dirender bertambah ke bawah oleh {% tr for ... %}
            "senin_lines": daily["senin"],
            "selasa_lines": daily["selasa"],
            "rabu_lines": daily["rabu"],
            "kamis_lines": daily["kamis"],
            "jumat_lines": daily["jumat"],
        }