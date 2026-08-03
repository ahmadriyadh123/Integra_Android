from typing import Dict, Any, List, Optional
from app.features.weekly_plan.repository import WeeklyPlanRepository

class WeeklyPlanService:
    def __init__(self, repo: WeeklyPlanRepository):
        self.repo = repo

    def _parse_many2one(self, val: Any, fallback: str = '-') -> str:
        if isinstance(val, list) and len(val) > 1:
            return str(val[1])
        if isinstance(val, str):
            return val
        return fallback

    def _clean_daily_lines(self, raw_lines: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        cleaned = []
        for r in raw_lines:
            cleaned.append({
                "id": r.get("id"),
                "waktu": str(r.get("waktu") or "-"),
                "aktivitas": str(r.get("aktivitas") or "-"),
                "media": str(r.get("media") or "-"),
                "sumber": str(r.get("sumber") or "-"),
                "penilaian": str(r.get("penilaian") or "-")
            })
        return cleaned

    def get_weekly_plan_list(self, uid: int, password: str) -> Dict[str, Any]:
        raw_plans = self.repo.get_weekly_plans(uid=uid, password=password)

        formatted_list = []
        for p in raw_plans:
            formatted_list.append({
                "id": p.get("id"),
                "kelas": self._parse_many2one(p.get("course_id"), "-"),
                "semester": self._parse_many2one(p.get("semester_id"), "-"),
                "tahun_ajaran": self._parse_many2one(p.get("tahun_ajaran_id"), "-"),
                "pekan": str(p.get("pekan") or "-"),
                "status": str(p.get("status") or "draft")
            })

        return {
            "total_records": len(formatted_list),
            "weekly_plans": formatted_list
        }

    def get_weekly_plan_detail(self, uid: int, password: str, plan_id: int) -> Optional[Dict[str, Any]]:
        header = self.repo.get_weekly_plan_by_id(uid=uid, password=password, plan_id=plan_id)
        if not header:
            return None

        # Ambil Tujuan Pembelajaran
        raw_tp = self.repo.get_tp_lines(uid=uid, password=password, plan_id=plan_id)
        formatted_tp = []
        for tp in raw_tp:
            formatted_tp.append({
                "id": tp.get("id"),
                "subject_name": self._parse_many2one(tp.get("subject_id"), "Mata Pelajaran"),
                "tp": str(tp.get("tp") or "-")
            })

        # Ambil Rincian Kegiatan Harian (Senin - Jumat)
        senin = self._clean_daily_lines(self.repo.get_daily_lines(uid, password, 'weekly.plan.sd.line', plan_id))
        selasa = self._clean_daily_lines(self.repo.get_daily_lines(uid, password, 'weekly.plan.sd.line.selasa', plan_id))
        rabu = self._clean_daily_lines(self.repo.get_daily_lines(uid, password, 'weekly.plan.sd.line.rabu', plan_id))
        kamis = self._clean_daily_lines(self.repo.get_daily_lines(uid, password, 'weekly.plan.sd.line.kamis', plan_id))
        jumat = self._clean_daily_lines(self.repo.get_daily_lines(uid, password, 'weekly.plan.sd.line.jumat', plan_id))

        return {
            "id": header.get("id"),
            "nama_sekolah": str(header.get("nama_sekolah") or "ERP Integra Edusolusi"),
            "alamat_sekolah": str(header.get("alamat_sekolah") or "Jl. Pena Kencana Bumi Serpong Damai"),
            "kelas": self._parse_many2one(header.get("course_id"), "-"),
            "semester": self._parse_many2one(header.get("semester_id"), "-"),
            "tahun_ajaran": self._parse_many2one(header.get("tahun_ajaran_id"), "-"),
            "pekan": str(header.get("pekan") or "-"),
            "tema": str(header.get("tema") or "-"),
            "nama_guru": str(header.get("nama_guru") or "-"),
            "nama_kepsek": str(header.get("nama_kepsek") or "-"),
            "status": str(header.get("status") or "draft"),
            "tujuan_pembelajaran": formatted_tp,
            "senin": senin,
            "selasa": selasa,
            "rabu": rabu,
            "kamis": kamis,
            "jumat": jumat
        }