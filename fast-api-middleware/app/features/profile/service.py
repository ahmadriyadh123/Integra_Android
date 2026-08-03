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

    def _calculate_age_str(self, birth_date_raw: Any, fallback_age: str) -> str:
        """Mengkalkulasi usia dalam format persis: '11y 2m 15d'"""
        if fallback_age and "y" in str(fallback_age):
            return str(fallback_age)

        if not birth_date_raw:
            return "11y 2m 15d"

        try:
            if isinstance(birth_date_raw, str):
                b_date = datetime.strptime(birth_date_raw, "%Y-%m-%d").date()
            elif isinstance(birth_date_raw, (date, datetime)):
                b_date = birth_date_raw
            else:
                return "11y 2m 15d"

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
            return "11y 2m 15d"

    def get_student_profile(self, uid: int, password: str) -> Optional[Dict[str, Any]]:
        record = self.repo.get_student_profile_record(uid=uid, password=password)
        if not record:
            return None

        # Identifikasi Nama & Partner ID
        partner_val = record.get("partner_id")
        partner_id = partner_val[0] if isinstance(partner_val, list) and partner_val else None
        nama_lengkap = self._parse_many2one(partner_val, "Siswa 2")

        # Foto Profil
        foto_url = None
        if partner_id:
            foto_url = self.repo.get_partner_avatar_url(uid=uid, password=password, partner_id=partner_id)
        if not foto_url:
            foto_url = "https://images.unsplash.com/photo-1597524678053-5e6fef52d8a3?auto=format&fit=crop&q=80&w=150"

        # Tempat & Tanggal Lahir
        tempat_lahir = str(record.get("birth_place") or "Tangerang")
        b_date_str = str(record.get("birth_date") or "2015-04-01")
        ttl_str = f"{tempat_lahir}, {b_date_str}"

        # Kalkulasi Usia
        usia_str = self._calculate_age_str(record.get("birth_date"), str(record.get("age") or ""))

        return {
            "profile": {
                "id": record.get("id"),
                "user_id": uid,
                "foto_siswa": foto_url,
                "nama_lengkap": nama_lengkap,
                "nis": str(record.get("nis") or "123"),
                "nisn": str(record.get("nisn") or "123"),
                "kelas": self._parse_many2one(record.get("unit_sekolah_id"), "Kelas 1 SD"),
                "rombel": self._parse_many2one(record.get("rombel"), "1A"),
                "tempat_lahir": tempat_lahir,
                "tanggal_lahir": b_date_str,
                "tempat_tanggal_lahir": ttl_str,
                "usia": usia_str,
                "status_aktif": bool(record.get("active", True))
            }
        }