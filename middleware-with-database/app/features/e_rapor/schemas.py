from pydantic import BaseModel, ConfigDict
from typing import List, Optional

class SubjectGradeLine(BaseModel):
    id: int
    subject_id: Optional[int] = None
    subject_name: str
    nilai_pengetahuan: float = 0.0
    nilai_keterampilan: float = 0.0
    predikat: Optional[str] = "-"

    model_config = ConfigDict(from_attributes=True)

class ReportCardHeader(BaseModel):
    id: int
    student_id: int
    student_name: str
    kelas: str
    semester: str
    tahun_ajaran: str
    rata_rata_nilai: float
    catatan_wali_kelas: Optional[str] = "-"
    status_keputusan: Optional[str] = "-"
    file_rapor_pdf: Optional[str] = None
    file_name: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

class ReportCardDetailResponse(BaseModel):
    id: int
    student_id: int
    student_name: str
    kelas: str
    rata_rata_nilai: float
    catatan_wali_kelas: Optional[str] = "-"
    file_rapor_pdf: Optional[str] = None
    file_name: Optional[str] = None
    subjects: List[SubjectGradeLine] = []

    model_config = ConfigDict(from_attributes=True)

class APIResponseReportList(BaseModel):
    success: bool
    message: str
    data: List[ReportCardHeader]

class APIResponseReportDetail(BaseModel):
    success: bool
    message: str
    data: Optional[ReportCardDetailResponse] = None