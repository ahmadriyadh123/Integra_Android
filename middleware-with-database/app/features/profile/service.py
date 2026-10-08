from typing import Dict, Any, Optional
from datetime import date, datetime
from app.features.profile.repository import ProfileRepository

class ProfileService:
    def __init__(self, repo: ProfileRepository):
        self.repo = repo

    def _parse_many2one(self, val: Any, fallback: str = '-') -> str:
        """Helper membaca nilai [id, name] bawaan Odoo Many2one"""
        if isinstance(val, list) and len(val) > 1:
            return str(val[1])
        if isinstance(val, str):
            return val
        return fallback

    def _calculate_age_str(self, birth_date_raw: Any, fallback_age: str = "") -> str:
        """Mengkalkulasi usia dari tanggal lahir"""
        if fallback_age and "y" in str(fallback_age):
            return str(fallback_age)

        if not birth_date_raw:
            return "-"

        try:
            if isinstance(birth_date_raw, str):
                b_date = datetime.strptime(birth_date_raw, "%Y-%m-%d").date()
            elif isinstance(birth_date_raw, (date, datetime)):
                b_date = birth_date_raw
            else:
                return "-"

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
            return "-"

    async def get_student_profile(
        self,
        user_id: int,
        partner_id: Optional[int] = None,
        student_id: Optional[int] = None,
    ) -> Optional[Dict[str, Any]]:
        record = await self.repo.get_student_profile_record(
            user_id=user_id,
            partner_id=partner_id,
            student_id=student_id,
        )
        if not record:
            return None

        p_id = record.get("partner_id")
        nama_lengkap = str(record.get("full_name") or "Siswa")

        foto_url = f"/api/v1/profile/image/{p_id}" if p_id else None

        # Tempat & Tanggal Lahir
        tempat_lahir = str(record.get("birth_place") or "-")
        b_date = record.get("birth_date")
        b_date_str = str(b_date) if b_date else "-"
        ttl_str = f"{tempat_lahir}, {b_date_str}" if tempat_lahir != "-" or b_date_str != "-" else "-"

        # Kalkulasi Usia
        usia_str = self._calculate_age_str(b_date, str(record.get("age") or ""))
        kelas = self._parse_many2one(record.get("kelas_name") or record.get("grade"), "-")
        rombel = self._parse_many2one(record.get("rombel_name") or record.get("rombel"), "-")

        return {
            "profile": {
                "id": record.get("id"),
                "user_id": user_id,
                "foto_siswa": foto_url,
                "nama_lengkap": nama_lengkap,
                "nis": str(record.get("nis") or "-"),
                "nisn": str(record.get("nisn") or "-"),
                "kelas": str(kelas or "-"),
                "rombel": str(rombel or "-"),
                "tempat_lahir": tempat_lahir,
                "tanggal_lahir": b_date_str,
                "tempat_tanggal_lahir": ttl_str,
                "usia": usia_str,
                "status_aktif": bool(record.get("active", True))
            }
        }