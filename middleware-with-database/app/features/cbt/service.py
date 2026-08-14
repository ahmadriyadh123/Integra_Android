# app/features/cbt/service.py
import logging
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional
from app.features.cbt.repository import CbtRepository

logger = logging.getLogger(__name__)

class CbtService:
    def __init__(self, repo: CbtRepository):
        self.repo = repo

    def _str(self, val: Any, fallback: str = '-') -> str:
        return str(val) if val and val is not False else fallback

    async def get_exam_list(self, course_id: Optional[int] = None) -> Dict[str, Any]:
        raw = await self.repo.get_schedules(course_id=course_id)
        exams = []
        for e in raw:
            t_mulai  = self._str(e.get('tanggal_mulai'), '')
            t_selesai = self._str(e.get('tanggal_selesai'), '')
            durasi    = int(e.get('durasi_menit') or 60)
            exams.append({
                "id": e.get("id"),
                "judul_ujian": self._str(e.get("name"), "Ujian CBT"),
                "status": self._str(e.get("status"), "draft"),
                "mata_pelajaran": self._str(e.get("mata_pelajaran_name")),
                "jenis_ujian": self._str(e.get("jenis_ujian_name")),
                "tanggal_mulai": t_mulai,
                "tanggal_selesai": t_selesai,
                "rentang_waktu": f"{t_mulai} - {t_selesai}",
                "durasi_menit": durasi,
                "durasi_label": f"Durasi: {durasi} menit",
                "jumlah_soal": int(e.get("jumlah_soal_ditampilkan") or 0),
                "passing_grade": float(e.get("passing_grade") or 0),
                "token_required": True,
            })
        return {
            "total_exams": len(exams),
            "exams": exams
        }

    async def verify_token(self, jadwal_id: int, token_input: str) -> bool:
        schedule = await self.repo.get_schedule_by_id(jadwal_id=jadwal_id)
        if not schedule:
            return False
        valid_token = self._str(schedule.get('token_ujian'), '').strip().upper()
        return token_input.strip().upper() == valid_token

    async def get_exam_questions(self, jadwal_id: int) -> Dict[str, Any]:
        schedule = await self.repo.get_schedule_by_id(jadwal_id=jadwal_id)
        if not schedule or not schedule.get('bank_soal_id'):
            raise ValueError("Jadwal Ujian atau Bank Soal tidak ditemukan.")
        
        bank_id = schedule['bank_soal_id']
        raw_questions = await self.repo.get_questions_by_bank_id(bank_soal_id=bank_id)
        
        questions = []
        for q in raw_questions:
            options = [
                {
                    "id": opt.get("id"),
                    "kode": self._str(opt.get("kode"), "A"),
                    "teks_jawaban": self._str(opt.get("teks_jawaban"), ""),
                }
                for opt in q.get('options', [])
            ]
            questions.append({
                "id": q.get("id"),
                "sequence": int(q.get("sequence") or 1),
                "jenis_soal": self._str(q.get("jenis_soal"), "pilihan_ganda"),
                "pertanyaan": self._str(q.get("pertanyaan"), ""),
                "bobot_nilai": float(q.get("bobot_nilai") or 1.0),
                "options": options,
            })
        return {
            "jadwal_ujian_id": jadwal_id,
            "judul_ujian": self._str(schedule.get("name"), "Ujian CBT"),
            "durasi_menit": int(schedule.get("durasi_menit") or 60),
            "acak_soal": bool(schedule.get("acak_soal")),
            "acak_jawaban": bool(schedule.get("acak_jawaban")),
            "total_soal": len(questions),
            "questions": questions,
        }

    async def submit_exam(
        self,
        student_id: int,
        course_id: int,
        jadwal_id: int,
        answers: List[Dict[str, Any]],
        waktu_mulai: Optional[str] = None
    ) -> Dict[str, Any]:
        schedule = await self.repo.get_schedule_by_id(jadwal_id=jadwal_id)
        if not schedule:
            raise ValueError("Jadwal ujian tidak ditemukan.")

        now_str = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S')

        # 1. Buat record hasil ujian
        hasil_data = {
            'jadwal_ujian_id': jadwal_id,
            'student_id': student_id,
            'kelas_id': course_id,
            'mata_pelajaran_id': schedule.get('mata_pelajaran_id'),
            'jenis_ujian_id': schedule.get('jenis_ujian_id'),
            'jumlah_soal': len(answers),
            'waktu_mulai': waktu_mulai or now_str,
            'waktu_selesai': now_str,
            'status': 'selesai',
            'token_verified': True,
        }
        hasil_id = await self.repo.create_hasil_ujian(data=hasil_data)

        # 2. Simpan jawaban
        jumlah_kosong = 0
        for answer in answers:
            soal_id = answer.get('soal_id')
            jawaban_pilihan_id = answer.get('jawaban_pilihan_id')
            jawaban_text = answer.get('jawaban_text')
            if not soal_id:
                continue

            jenis = answer.get('jenis_soal', 'pilihan_ganda')
            if jawaban_pilihan_id is None and not jawaban_text:
                jumlah_kosong += 1
                jenis = 'pilihan_ganda'

            jawaban_data = {
                'hasil_ujian_id': hasil_id,
                'soal_id': soal_id,
                'jenis_soal': jenis,
                'waktu_jawab': now_str,
                'jawaban_pilihan_id': jawaban_pilihan_id,
                'jawaban_text': jawaban_text
            }
            try:
                await self.repo.create_jawaban_siswa(data=jawaban_data)
            except Exception as e:
                logger.warning(f"[cbt] gagal simpan jawaban soal_id={soal_id}: {e}")

        # 3. Update rekap hasil ujian
        total_dijawab = len(answers) - jumlah_kosong
        update_vals = {
            'jumlah_benar': 0,
            'jumlah_salah': 0,
            'jumlah_tidak_dijawab': jumlah_kosong,
        }
        try:
            await self.repo.update_hasil_ujian(hasil_id=hasil_id, values=update_vals)
        except Exception as e:
            logger.warning(f"[cbt] gagal update hasil ujian id={hasil_id}: {e}")

        return {
            "hasil_ujian_id": hasil_id,
            "jumlah_soal": len(answers),
            "jumlah_dijawab": total_dijawab,
            "jumlah_tidak_dijawab": jumlah_kosong,
            "status": "selesai",
            "message": "Ujian berhasil diselesaikan."
        }

    async def get_riwayat_ujian(self, student_id: int) -> Dict[str, Any]:
        raw = await self.repo.get_hasil_ujian(student_id=student_id)
        hasil_list = []
        for h in raw:
            hasil_list.append({
                "id": h.get("id"),
                "judul_ujian": self._str(h.get("judul_ujian")),
                "mata_pelajaran": self._str(h.get("mata_pelajaran_name")),
                "jenis_ujian": self._str(h.get("jenis_ujian_name")),
                "nilai": float(h.get("nilai") or 0),
                "status": self._str(h.get("status"), "-"),
                "keterangan_kelulusan": self._str(h.get("keterangan_kelulusan"), "-"),
                "jumlah_soal": int(h.get("jumlah_soal") or 0),
                "jumlah_benar": int(h.get("jumlah_benar") or 0),
                "jumlah_salah": int(h.get("jumlah_salah") or 0),
                "jumlah_tidak_dijawab": int(h.get("jumlah_tidak_dijawab") or 0),
                "waktu_mulai": self._str(h.get("waktu_mulai"), ""),
                "waktu_selesai": self._str(h.get("waktu_selesai"), ""),
                "durasi_pengerjaan": float(h.get("durasi_pengerjaan") or 0),
            })
        return {
            "total": len(hasil_list),
            "riwayat": hasil_list
        }
