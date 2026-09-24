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

    def get_student_profile(
        self,
        uid: int,
        password: str,
        user_id: Optional[int] = None,
        partner_id: Optional[int] = None,
        student_id: Optional[int] = None,
    ) -> Optional[Dict[str, Any]]:
        record = self.repo.get_student_profile_record(
            uid=uid,
            password=password,
            user_id=user_id,
            partner_id=partner_id,
            student_id=student_id,
        )
        if not record:
            return None


        # Susun identitas utama dan partner Odoo untuk response profil.
        partner_val = record.get("partner_id")
        partner_id = partner_val[0] if isinstance(partner_val, list) and partner_val else None
        nama_lengkap = self._parse_many2one(partner_val, "-")

        # Normalisasi foto agar client menerima URL yang konsisten.
        foto_url = None
        if partner_id:
            foto_url = self.repo.get_partner_avatar_url(uid=uid, password=password, partner_id=partner_id)

        # Gabungkan tempat dan tanggal lahir untuk tampilan profil.
        tempat_lahir = str(record.get("birth_place") or "-")
        b_date_str = str(record.get("birth_date") or "-")
        ttl_str = f"{tempat_lahir}, {b_date_str}" if tempat_lahir != "-" or b_date_str != "-" else "-"

        # Hitung usia hanya jika tanggal lahir tersedia dan valid.
        usia_str = self._calculate_age_str(record.get("birth_date"), str(record.get("age") or ""))

        return {
            "profile": {
                "id": record.get("id"),
                "user_id": uid,
                "partner_id": partner_id,
                "foto_siswa": foto_url,
                "nama_lengkap": nama_lengkap,
                "nis": str(record.get("nis") or "-"),
                "nisn": str(record.get("nisn") or "-"),
                "kelas": self._parse_many2one(record.get("grade"), "-"),
                "rombel": self._parse_many2one(record.get("rombel"), "-"),
                "tempat_lahir": tempat_lahir,
                "tanggal_lahir": b_date_str,
                "tempat_tanggal_lahir": ttl_str,
                "usia": usia_str,
                "status_aktif": bool(record.get("active", True))
            }
        }