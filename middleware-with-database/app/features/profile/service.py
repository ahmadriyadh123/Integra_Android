# app/features/profile/service.py
from typing import Dict, Any, Optional
from datetime import date, datetime
from app.features.profile.repository import ProfileRepository

class ProfileService:
    def __init__(self, repo: ProfileRepository):
        self.repo = repo

    def _calculate_age_str(self, birth_date_raw: Any) -> str:
        """Mengkalkulasi usia dalam format persis: '11y 2m 15d'"""
        if not birth_date_raw:
            return "0y 0m 0d"
        try:
            if isinstance(birth_date_raw, str):
                b_date = datetime.strptime(birth_date_raw, "%Y-%m-%d").date()
            elif isinstance(birth_date_raw, (date, datetime)):
                b_date = birth_date_raw
            else:
                return "0y 0m 0d"

            today = date.today()
            years = today.year - b_date.year
            months = today.month - b_date.month
            days = today.day - b_date.day

            if days < 0:
                months -= 1
                days += 30
            if months < 0:
                years -= 1
                months += 12

            return f"{years}y {months}m {days}d"
        except Exception:
            return "0y 0m 0d"

    async def get_student_profile(self, user_id: int) -> Optional[Dict[str, Any]]:
        record = await self.repo.get_student_profile_record(user_id=user_id)
        if not record:
            return None

        partner_id = record.get("partner_id")
        nama_lengkap = str(record.get("full_name") or "Siswa")

        # Foto Profil
        foto_url = None
        if partner_id:
            foto_url = await self.repo.get_partner_avatar_url(partner_id=partner_id)
        if not foto_url:
            foto_url = "https://images.unsplash.com/photo-1597524678053-5e6fef52d8a3?auto=format&fit=crop&q=80&w=150"

        # Tempat & Tanggal Lahir
        tempat_lahir = str(record.get("birth_place") or "-")
        b_date = record.get("birth_date")
        b_date_str = str(b_date) if b_date else "-"
        ttl_str = f"{tempat_lahir}, {b_date_str}"

        # Kalkulasi Usia
        usia_str = self._calculate_age_str(b_date)

        return {
            "profile": {
                "id": record.get("id"),
                "user_id": user_id,
                "foto_siswa": foto_url,
                "nama_lengkap": nama_lengkap,
                "nis": str(record.get("nis") or "-"),
                "nisn": str(record.get("nisn") or "-"),
                "kelas": str(record.get("kelas_name") or "-"),
                "rombel": str(record.get("rombel_name") or "-"),
                "tempat_lahir": tempat_lahir,
                "tanggal_lahir": b_date_str,
                "tempat_tanggal_lahir": ttl_str,
                "usia": usia_str,
                "status_aktif": bool(record.get("active", True))
            }
        }