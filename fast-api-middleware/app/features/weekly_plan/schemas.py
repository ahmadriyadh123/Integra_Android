from pydantic import BaseModel
from typing import List, Optional


class DailyActivityLine(BaseModel):
    id: int
    waktu: Optional[str] = "-"
    aktivitas: Optional[str] = "-"
    media: Optional[str] = "-"
    sumber: Optional[str] = "-"
    penilaian: Optional[str] = "-"


class TargetPembelajaranLine(BaseModel):
    id: int
    subject_name: str
    tp: str


class WeeklyPlanItemResponse(BaseModel):
    id: int
    kelas: str
    semester: str
    tahun_ajaran: str
    pekan: str
    tema: Optional[str] = "-"
    nama_guru: Optional[str] = "-"
    status: str


class WeeklyPlanListResponse(BaseModel):
    total_records: int
    weekly_plans: List[WeeklyPlanItemResponse]


class APIResponseWeeklyPlanList(BaseModel):
    success: bool
    message: str
    data: WeeklyPlanListResponse


class WeeklyPlanDetailResponse(BaseModel):
    id: int
    nama_sekolah: str
    alamat_sekolah: str
    kelas: str
    semester: str
    tahun_ajaran: str
    pekan: str
    tema: Optional[str] = "-"
    nama_guru: Optional[str] = "-"
    nama_kepsek: Optional[str] = "-"
    status: str
    tujuan_pembelajaran: List[TargetPembelajaranLine]
    senin: List[DailyActivityLine]
    selasa: List[DailyActivityLine]
    rabu: List[DailyActivityLine]
    kamis: List[DailyActivityLine]
    jumat: List[DailyActivityLine]


class APIResponseWeeklyPlanDetail(BaseModel):
    success: bool
    message: str
    data: Optional[WeeklyPlanDetailResponse] = None
