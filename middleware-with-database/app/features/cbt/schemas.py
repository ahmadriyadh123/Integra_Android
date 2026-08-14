# app/features/cbt/schemas.py
from pydantic import BaseModel
from typing import List, Optional

class CbtExamItemResponse(BaseModel):
    id: int
    judul_ujian: str
    status: str
    mata_pelajaran: str
    jenis_ujian: Optional[str] = "-"
    tanggal_mulai: str
    tanggal_selesai: str
    rentang_waktu: str
    durasi_menit: int
    durasi_label: str
    jumlah_soal: int
    passing_grade: float = 0.0
    token_required: bool = True

class CbtExamListResponse(BaseModel):
    total_exams: int
    exams: List[CbtExamItemResponse]

class APIResponseCbtList(BaseModel):
    success: bool
    message: str
    data: CbtExamListResponse

class VerifyTokenRequest(BaseModel):
    jadwal_ujian_id: int
    token_input: str

class QuestionOptionSchema(BaseModel):
    id: int
    kode: str
    teks_jawaban: str

class QuestionSchema(BaseModel):
    id: int
    sequence: int
    jenis_soal: str
    pertanyaan: str
    bobot_nilai: float = 1.0
    options: List[QuestionOptionSchema]

class CbtExamQuestionsResponse(BaseModel):
    jadwal_ujian_id: int
    judul_ujian: str
    durasi_menit: int
    acak_soal: bool = False
    acak_jawaban: bool = False
    total_soal: int
    questions: List[QuestionSchema]

class APIResponseCbtQuestions(BaseModel):
    success: bool
    message: str
    data: CbtExamQuestionsResponse

class SingleAnswerPayload(BaseModel):
    soal_id: int
    jenis_soal: str = "pilihan_ganda"
    jawaban_pilihan_id: Optional[int] = None
    jawaban_text: Optional[str] = None

class SubmitExamPayload(BaseModel):
    jadwal_ujian_id: int
    waktu_mulai: Optional[str] = None
    answers: List[SingleAnswerPayload]

class SubmitExamResponse(BaseModel):
    hasil_ujian_id: int
    jumlah_soal: int
    jumlah_dijawab: int
    jumlah_tidak_dijawab: int
    status: str
    message: str

class APIResponseSubmitExam(BaseModel):
    success: bool
    message: str
    data: SubmitExamResponse

class HasilUjianItem(BaseModel):
    id: int
    judul_ujian: str
    mata_pelajaran: str
    jenis_ujian: str
    nilai: float
    status: str
    keterangan_kelulusan: str
    jumlah_soal: int
    jumlah_benar: int
    jumlah_salah: int
    jumlah_tidak_dijawab: int
    waktu_mulai: str
    waktu_selesai: str
    durasi_pengerjaan: float

class RiwayatUjianResponse(BaseModel):
    total: int
    riwayat: List[HasilUjianItem]

class APIResponseRiwayatUjian(BaseModel):
    success: bool
    message: str
    data: RiwayatUjianResponse