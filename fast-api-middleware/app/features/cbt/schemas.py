from pydantic import BaseModel
from typing import List, Optional

# --- Response Item Jadwal Ujian ---
class CbtExamItemResponse(BaseModel):
    id: int
    judul_ujian: str
    status: str
    mata_pelajaran: str
    tanggal_mulai: str
    tanggal_selesai: str
    rentang_waktu: str
    durasi_menit: int
    durasi_label: str
    jumlah_soal: int
    token_required: bool = True

class CbtExamListResponse(BaseModel):
    total_exams: int
    exams: List[CbtExamItemResponse]

class APIResponseCbtList(BaseModel):
    success: bool
    message: str
    data: CbtExamListResponse

# --- Request Verifikasi Token Ujian ---
class VerifyTokenRequest(BaseModel):
    jadwal_ujian_id: int
    token_input: str

# --- Response Detail Soal & Jawaban Ujian ---
class QuestionOptionSchema(BaseModel):
    id: int
    kode: str                  # A, B, C, D
    teks_jawaban: str

class QuestionSchema(BaseModel):
    id: int
    sequence: int
    jenis_soal: str            # 'pilihan_ganda' / 'essay'
    pertanyaan: str
    options: List[QuestionOptionSchema]

class CbtExamQuestionsResponse(BaseModel):
    jadwal_ujian_id: int
    judul_ujian: str
    durasi_menit: int
    total_soal: int
    questions: List[QuestionSchema]

class APIResponseCbtQuestions(BaseModel):
    success: bool
    message: str
    data: CbtExamQuestionsResponse

# --- Request Submit Jawaban Ujian ---
class SingleAnswerPayload(BaseModel):
    soal_id: int
    jawaban_pilihan_id: Optional[int] = None
    jawaban_text: Optional[str] = None

class SubmitExamPayload(BaseModel):
    jadwal_ujian_id: int
    answers: List[SingleAnswerPayload]