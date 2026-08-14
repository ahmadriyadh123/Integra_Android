# app/features/buku_komunikasi/schemas.py
from pydantic import BaseModel
from typing import List, Optional

class DailyNoteLineResponse(BaseModel):
    id: int
    pekan_ke: int
    bulan: str
    senin: str
    feedback_senin: Optional[str] = "-"
    selasa: str
    feedback_selasa: Optional[str] = "-"
    rabu: str
    feedback_rabu: Optional[str] = "-"
    kamis: str
    feedback_kamis: Optional[str] = "-"
    jumat: str
    feedback_jumat: Optional[str] = "-"

class BukuKomunikasiDetailResponse(BaseModel):
    id: int
    student_name: str
    kelas: str
    tahun_ajaran: str
    status: str
    lines: List[DailyNoteLineResponse] = []

class APIResponseBukuKomunikasi(BaseModel):
    success: bool
    message: str
    data: Optional[BukuKomunikasiDetailResponse] = None

class UpdateFeedbackRequest(BaseModel):
    line_id: int
    day: str
    feedback_text: str