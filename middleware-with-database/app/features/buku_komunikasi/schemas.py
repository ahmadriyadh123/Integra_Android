from typing import List, Optional

from pydantic import BaseModel, Field


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
    write_date: Optional[str] = None


class BukuKomunikasiDetailResponse(BaseModel):
    id: int
    student_name: str
    kelas: str
    tahun_ajaran: str
    status: str
    lines: List[DailyNoteLineResponse] = Field(default_factory=list)


class APIResponseBukuKomunikasi(BaseModel):
    success: bool
    message: str
    data: Optional[BukuKomunikasiDetailResponse] = None


class UpdateNoteRequest(BaseModel):
    line_id: int
    day: str
    note_text: str
    month: Optional[str] = None
    week: Optional[int] = None


class UpdateFeedbackRequest(BaseModel):
    line_id: int
    day: str
    feedback_text: str


class BukuKomunikasiSyncResponse(BaseModel):
    header_id: int
    items: List[DailyNoteLineResponse]
    removed_ids: List[int]
    next_cursor: str
    full_sync: bool


class APIResponseBukuKomunikasiSync(BaseModel):
    success: bool
    message: str
    data: BukuKomunikasiSyncResponse


class UpdateFeedbackRequest(BaseModel):
    line_id: int
    day: str
    feedback_text: str