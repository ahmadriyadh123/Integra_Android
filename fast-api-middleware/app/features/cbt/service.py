from typing import Dict, Any, List, Optional
from app.features.cbt.repository import CbtRepository

class CbtService:
    def __init__(self, repo: CbtRepository):
        self.repo = repo

    def _parse_many2one(self, val: Any, fallback: str = '-') -> str:
        if isinstance(val, list) and len(val) > 1:
            return str(val[1])
        if isinstance(val, str):
            return val
        return fallback

    def get_exam_list(self, uid: int, password: str) -> Dict[str, Any]:
        raw_schedules = self.repo.get_schedules(uid=uid, password=password)

        formatted_list = []
        for e in raw_schedules:
            t_mulai = str(e.get('tanggal_mulai') or "07/06/2026 11:30:00")
            t_selesai = str(e.get('tanggal_selesai') or "07/06/2026 12:30:00")
            durasi = int(e.get('durasi_menit') or 60)

            formatted_list.append({
                "id": e.get("id"),
                "judul_ujian": str(e.get("name") or "Ujian CBT"),
                "status": str(e.get("status") or "Berlangsung"),
                "mata_pelajaran": self._parse_many2one(e.get("mata_pelajaran_id"), "Matematika"),
                "tanggal_mulai": t_mulai,
                "tanggal_selesai": t_selesai,
                "rentang_waktu": f"{t_mulai} - {t_selesai}",
                "durasi_menit": durasi,
                "durasi_label": f"Durasi: {durasi} menit",
                "jumlah_soal": int(e.get("jumlah_soal_ditampilkan") or 40),
                "token_required": True
            })

        return {
            "total_exams": len(formatted_list),
            "exams": formatted_list
        }

    def verify_token(self, uid: int, password: str, jadwal_id: int, token_input: str) -> bool:
        schedule = self.repo.get_schedule_by_id(uid=uid, password=password, jadwal_id=jadwal_id)
        if not schedule:
            return False

        valid_token = str(schedule.get('token_ujian') or '').strip().upper()
        return token_input.strip().upper() == valid_token

    def get_exam_questions(self, uid: int, password: str, jadwal_id: int) -> Dict[str, Any]:
        schedule = self.repo.get_schedule_by_id(uid=uid, password=password, jadwal_id=jadwal_id)
        if not schedule or not schedule.get('bank_soal_id'):
            raise ValueError("Jadwal Ujian atau Bank Soal tidak ditemukan.")

        bank_id = schedule['bank_soal_id'][0] if isinstance(schedule['bank_soal_id'], list) else schedule['bank_soal_id']
        raw_questions = self.repo.get_questions_by_bank_id(uid=uid, password=password, bank_soal_id=bank_id)

        questions = []
        for q in raw_questions:
            options = []
            for opt in q.get('options', []):
                options.append({
                    "id": opt.get("id"),
                    "kode": str(opt.get("kode") or "A"),
                    "teks_jawaban": str(opt.get("teks_jawaban") or "")
                })

            questions.append({
                "id": q.get("id"),
                "sequence": int(q.get("sequence") or 1),
                "jenis_soal": str(q.get("jenis_soal") or "pilihan_ganda"),
                "pertanyaan": str(q.get("pertanyaan") or ""),
                "options": options
            })

        return {
            "jadwal_ujian_id": jadwal_id,
            "judul_ujian": str(schedule.get("name") or "Ujian CBT"),
            "durasi_menit": int(schedule.get("durasi_menit") or 60),
            "total_soal": len(questions),
            "questions": questions
        }