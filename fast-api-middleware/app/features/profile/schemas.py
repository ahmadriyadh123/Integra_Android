from pydantic import BaseModel
from typing import Optional

class ProfileDataResponse(BaseModel):
    id: int
    user_id: int
    partner_id: Optional[int] = None
    foto_siswa: Optional[str] = None
    nama_lengkap: str
    nis: str
    nisn: str
    kelas: str
    rombel: str
    tempat_lahir: str
    tanggal_lahir: str
    tempat_tanggal_lahir: str
    usia: str
    status_aktif: bool = True

class ProfileSummaryResponse(BaseModel):
    profile: ProfileDataResponse

class APIResponseProfile(BaseModel):
    success: bool
    message: str
    data: Optional[ProfileSummaryResponse] = None