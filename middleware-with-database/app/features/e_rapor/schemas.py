from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field

class SubjectGradeLine(BaseModel):
    id: int
    subject_id: Optional[int] = None
    subject_name: str
    nilai_pengetahuan: float = 0.0
    nilai_keterampilan: float = 0.0
    predikat: Optional[str] = "-"
    nilai_akhir: Optional[float] = None
    catatan: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

class ReportCardHeader(BaseModel):
    id: int
    student_id: int
    student_name: str
    jenis_rapor: str = "-"
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
    jenis_rapor: str = "-"
    kelas: str
    semester: str = "-"
    tahun_ajaran: str = "-"
    fase: Optional[str] = None
    rata_rata_nilai: float
    catatan_wali_kelas: Optional[str] = "-"
    file_rapor_pdf: Optional[str] = None
    file_name: Optional[str] = None
    subjects: List[SubjectGradeLine] = Field(default_factory=list)
    muatan_lokal: List[SubjectGradeLine] = Field(default_factory=list)
    nis: Optional[str] = None
    nisn: Optional[str] = None
    nama_sekolah: Optional[str] = None
    alamat_sekolah: Optional[str] = None
    tanggal_pengesahan: Optional[str] = None
    wali_kelas: Optional[str] = None
    has_pdf_attachment: bool = False

    model_config = ConfigDict(from_attributes=True)

class APIResponseReportList(BaseModel):
    success: bool
    message: str
    data: List[ReportCardHeader]

class APIResponseReportDetail(BaseModel):
    success: bool
    message: str
    data: Optional[ReportCardDetailResponse] = None