import logging
from typing import Dict, Any, List, Optional
from app.features.weekly_plan.repository import WeeklyPlanRepository

logger = logging.getLogger(__name__)


class WeeklyPlanService:
    def __init__(self, repo: WeeklyPlanRepository):
        self.repo = repo

    def _parse_many2one(self, val: Any, fallback: str = '-') -> str:
        if isinstance(val, list) and len(val) > 1:
            return str(val[1])
        if isinstance(val, str):
            return val
        return fallback

    def _str(self, val: Any, fallback: str = '-') -> str:
        if val and val is not False:
            return str(val)
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

        # Tujuan Pembelajaran
        raw_tp = self.repo.get_tp_lines(
            uid=uid, password=password,
            plan_id=plan_id, jenjang=jenjang
        )
        tp_list = [
            {
                "id": tp.get("id"),
                "subject_name": self._parse_many2one(tp.get("subject_id"), "Mata Pelajaran"),
                "tp": self._str(tp.get("tp")),
            }
            for tp in raw_tp
        ]

        # Rincian kegiatan harian Senin–Jumat
        days = ['senin', 'selasa', 'rabu', 'kamis', 'jumat']
        daily = {}
        for hari in days:
            raw_lines = self.repo.get_daily_lines(
                uid=uid, password=password,
                plan_id=plan_id, hari=hari, jenjang=jenjang
            )
            daily[hari] = self._clean_daily_lines(raw_lines)

        return {
            "id": header.get("id"),
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
            "tujuan_pembelajaran": tp_list,
            "senin": daily["senin"],
            "selasa": daily["selasa"],
            "rabu": daily["rabu"],
            "kamis": daily["kamis"],
            "jumat": daily["jumat"],
        }
