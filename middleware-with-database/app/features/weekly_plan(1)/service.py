import logging
from typing import Dict, Any, List, Optional
from app.features.weekly_plan.repository import WeeklyPlanRepository

logger = logging.getLogger(__name__)

class WeeklyPlanService:
    def __init__(self, repo: WeeklyPlanRepository):
        self.repo = repo

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

    async def get_weekly_plan_list(
        self, jenjang: str = 'sd', course_id: Optional[int] = None
    ) -> Dict[str, Any]:
        raw = await self.repo.get_weekly_plans(jenjang=jenjang, course_id=course_id)

        weekly_plans = []
        for p in raw:
            weekly_plans.append({
                "id": p.get("id"),
                "kelas": self._str(p.get("course_name")),
                "semester": self._str(p.get("semester_name")),
                "tahun_ajaran": self._str(p.get("tahun_ajaran_name")),
                "pekan": self._str(p.get("pekan")),
                "tema": self._str(p.get("tema")),
                "nama_guru": self._str(p.get("nama_guru")),
                "status": self._str(p.get("status"), "draft"),
            })

        return {
            "total_records": len(weekly_plans),
            "weekly_plans": weekly_plans
        }

    async def get_weekly_plan_detail(
        self, plan_id: int, jenjang: str = 'sd'
    ) -> Optional[Dict[str, Any]]:
        header = await self.repo.get_weekly_plan_by_id(plan_id=plan_id, jenjang=jenjang)
        if not header:
            return None

        # Tujuan Pembelajaran
        raw_tp = await self.repo.get_tp_lines(plan_id=plan_id, jenjang=jenjang)
        tp_list = [
            {
                "id": tp.get("id"),
                "subject_name": self._str(tp.get("subject_name"), "Mata Pelajaran"),
                "tp": self._str(tp.get("tp")),
            }
            for tp in raw_tp
        ]

        # Rincian kegiatan harian Senin–Jumat
        days = ['senin', 'selasa', 'rabu', 'kamis', 'jumat']
        daily = {}
        for hari in days:
            raw_lines = await self.repo.get_daily_lines(plan_id=plan_id, hari=hari, jenjang=jenjang)
            daily[hari] = self._clean_daily_lines(raw_lines)

        return {
            "id": header.get("id"),
            "nama_sekolah": self._str(header.get("nama_sekolah"), "ERP Integra Edusolusi"),
            "alamat_sekolah": self._str(header.get("alamat_sekolah"), "Jl. Pena Kencana BSD"),
            "kelas": self._str(header.get("course_name")),
            "semester": self._str(header.get("semester_name")),
            "tahun_ajaran": self._str(header.get("tahun_ajaran_name")),
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