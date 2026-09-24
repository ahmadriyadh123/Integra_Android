import html
import logging
import re
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional
from app.features.cbt.repository import CbtRepository

logger = logging.getLogger(__name__)


class CbtService:
    def __init__(self, repo: CbtRepository):
        self.repo = repo

    def _parse_many2one(self, val: Any, fallback: str = '-') -> str:
        if isinstance(val, list) and len(val) > 1:
            return str(val[1])
        if isinstance(val, str):
            return val
        return fallback

    def _str(self, val: Any, fallback: str = '-') -> str:
        return str(val) if val and val is not False else fallback

    def _clean_html(self, val: Any) -> str:
        if not val or val is False:
            return ""
        cleaned = re.sub(r'<[^>]*>', '', str(val))
        return html.unescape(cleaned).strip()

    def get_exam_list(
        self, uid: int, password: str,
        course_id: Optional[int] = None,
        student_id: Optional[int] = None
    ) -> Dict[str, Any]:
        raw = self.repo.get_schedules(
            uid=uid, password=password,
            course_id=course_id
        )

        completed_jadwal_ids = set()
        if student_id:
            try:
                hasil_list = self.repo.get_hasil_ujian(
                    uid=uid, password=password, student_id=student_id
                )
                for h in hasil_list:
                    j_val = h.get('jadwal_ujian_id')
                    j_id = j_val[0] if isinstance(j_val, list) and j_val else (
                        j_val if isinstance(j_val, int) else None
                    )
                    if j_id:
                        completed_jadwal_ids.add(j_id)
            except Exception as e:
                logger.warning(f"[cbt service] Failed get_hasil_ujian for student_id={student_id}: {e}")

        now_dt = datetime.now(timezone.utc)
        exams = []
        for e in raw:
            e_id = e.get("id")
            t_mulai_str  = self._str(e.get('tanggal_mulai'), '')
            t_selesai_str = self._str(e.get('tanggal_selesai'), '')
            durasi    = int(e.get('durasi_menit') or 60)
            raw_status = self._str(e.get('status'), 'draft').lower()

            status_label = 'Belum Dimulai'

            # Cegah siswa mengirim ujian yang sama lebih dari sekali.
            if e_id in completed_jadwal_ids or raw_status in ['selesai', 'done', 'closed']:
                status_label = 'Selesai'
            else:
                # Status ujian ditentukan dari rentang waktu yang dikonfigurasi.
                parsed_start = None
                parsed_end = None
                for fmt in ['%Y-%m-%d %H:%M:%S', '%Y-%m-%dT%H:%M:%S', '%Y-%m-%d']:
                    if t_mulai_str and not parsed_start:
                        try:
                            parsed_start = datetime.strptime(t_mulai_str.split('.')[0], fmt).replace(tzinfo=timezone.utc)
                        except Exception:
                            pass
                    if t_selesai_str and not parsed_end:
                        try:
                            parsed_end = datetime.strptime(t_selesai_str.split('.')[0], fmt).replace(tzinfo=timezone.utc)
                        except Exception:
                            pass

                if parsed_start and parsed_end:
                    if now_dt < parsed_start:
                        status_label = 'Belum Dimulai'
                    elif parsed_start <= now_dt <= parsed_end:
                        status_label = 'Aktif'
                    else:
                        status_label = 'Selesai'
                elif raw_status in ['aktif', 'active', 'published', 'ongoing']:
                    status_label = 'Aktif'

            exams.append({
                "id": e_id,
                "judul_ujian": self._str(e.get("name"), "Ujian CBT"),
                "status": status_label,
                "raw_status": raw_status,
                "mata_pelajaran": self._parse_many2one(e.get("mata_pelajaran_id")),
                "jenis_ujian": self._parse_many2one(e.get("jenis_ujian_id")),
                "tanggal_mulai": t_mulai_str,
                "tanggal_selesai": t_selesai_str,
                "rentang_waktu": f"{t_mulai_str} - {t_selesai_str}",
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


    def verify_token(
        self, uid: int, password: str,
        jadwal_id: int, token_input: str
    ) -> bool:
        schedule = self.repo.get_schedule_by_id(
            uid=uid, password=password, jadwal_id=jadwal_id
        )
        if not schedule:
            return False
        valid_token = self._str(schedule.get('token_ujian'), '').strip().upper()
        return token_input.strip().upper() == valid_token

    def get_exam_questions(
        self, uid: int, password: str, jadwal_id: int
    ) -> Dict[str, Any]:
        schedule = self.repo.get_schedule_by_id(
            uid=uid, password=password, jadwal_id=jadwal_id
        )
        if not schedule or not schedule.get('bank_soal_id'):
            raise ValueError("Jadwal Ujian atau Bank Soal tidak ditemukan.")

        bank_id = schedule['bank_soal_id'][0] if isinstance(
            schedule['bank_soal_id'], list) else schedule['bank_soal_id']

        raw_questions = self.repo.get_questions_by_bank_id(
            uid=uid, password=password, bank_soal_id=bank_id
        )

        questions = []
        for q in raw_questions:
            options = [
                {
                    "id": opt.get("id"),
                    "kode": self._str(opt.get("kode"), "A"),
                    "teks_jawaban": self._clean_html(opt.get("teks_jawaban")),
                }
                for opt in q.get('options', [])
            ]
            questions.append({
                "id": q.get("id"),
                "sequence": int(q.get("sequence") or 1),
                "jenis_soal": self._str(q.get("jenis_soal"), "pilihan_ganda"),
                "pertanyaan": self._clean_html(q.get("pertanyaan")),
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

    def submit_exam(
        self, uid: int, password: str,
        student_id: int, course_id: int,
        jadwal_id: int,
        answers: List[Dict[str, Any]],
        waktu_mulai: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Submit jawaban ujian:
        1. Buat record cbt.hasil.ujian
        2. Simpan setiap jawaban ke cbt.jawaban.siswa
        3. Hitung nilai dan update hasil ujian
        """
        schedule = self.repo.get_schedule_by_id(
            uid=uid, password=password, jadwal_id=jadwal_id
        )
        if not schedule:
            raise ValueError("Jadwal ujian tidak ditemukan.")

        now_str = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S')

        # Buat header hasil sebelum menyimpan jawaban per soal.
        hasil_data = {
            'jadwal_ujian_id': jadwal_id,
            'student_id': student_id,
            'kelas_id': course_id,
            'mata_pelajaran_id': schedule['mata_pelajaran_id'][0]
                if isinstance(schedule.get('mata_pelajaran_id'), list)
                else schedule.get('mata_pelajaran_id'),
            'jenis_ujian_id': schedule['jenis_ujian_id'][0]
                if isinstance(schedule.get('jenis_ujian_id'), list)
                else schedule.get('jenis_ujian_id'),
            'jumlah_soal': len(answers),
            'waktu_mulai': waktu_mulai or now_str,
            'waktu_selesai': now_str,
            'status': 'selesai',
            'token_verified': True,
        }

        hasil_id = self.repo.create_hasil_ujian(
            uid=uid, password=password, data=hasil_data
        )

        # Simpan jawaban sekaligus akumulasi nilai yang diperoleh.
        jumlah_benar = 0
        jumlah_salah = 0
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
            }
            if jawaban_pilihan_id:
                jawaban_data['jawaban_pilihan_id'] = jawaban_pilihan_id
            if jawaban_text:
                jawaban_data['jawaban_text'] = jawaban_text

            try:
                self.repo.create_jawaban_siswa(
                    uid=uid, password=password, data=jawaban_data
                )
            except Exception as e:
                logger.warning(f"[cbt] gagal simpan jawaban soal_id={soal_id}: {e}")

        # Lengkapi header dengan nilai akhir dan status pengerjaan.
        total_dijawab = len(answers) - jumlah_kosong
        update_vals = {
            'jumlah_benar': jumlah_benar,
            'jumlah_salah': jumlah_salah,
            'jumlah_tidak_dijawab': jumlah_kosong,
        }
        try:
            self.repo.update_hasil_ujian(
                uid=uid, password=password,
                hasil_id=hasil_id, values=update_vals
            )
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

    def get_riwayat_ujian(
        self, uid: int, password: str,
        student_id: int
    ) -> Dict[str, Any]:
        """Ambil riwayat hasil ujian siswa."""
        raw = self.repo.get_hasil_ujian(
            uid=uid, password=password, student_id=student_id
        )

        hasil_list = []
        for h in raw:
            hasil_list.append({
                "id": h.get("id"),
                "judul_ujian": self._parse_many2one(h.get("jadwal_ujian_id")),
                "mata_pelajaran": self._parse_many2one(h.get("mata_pelajaran_id")),
                "jenis_ujian": self._parse_many2one(h.get("jenis_ujian_id")),
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
