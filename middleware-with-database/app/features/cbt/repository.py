import logging
from typing import List, Dict, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

logger = logging.getLogger(__name__)

class CbtRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    async def get_schedules(self, course_id: Optional[int] = None, student_id: Optional[int] = None) -> List[Dict[str, Any]]:
        """
        Ambil jadwal ujian CBT yang aktif khusus kelas siswa yang login.
        """
        # Ambil grade (course_id) dari op_student jika course_id belum tersedia
        if course_id is None and student_id is not None:
            grade_query = text("SELECT grade FROM op_student WHERE id = :student_id LIMIT 1;")
            res = await self.db.execute(grade_query, {"student_id": student_id})
            row = res.fetchone()
            if row and row[0]:
                course_id = int(row[0])

        base_query = """
            SELECT DISTINCT
                j.id, j.name, j.status, j.mata_pelajaran_id,
                mp.name AS mata_pelajaran_name,
                j.jenis_ujian_id, ju.name AS jenis_ujian_name,
                j.tanggal_mulai, j.tanggal_selesai,
                j.durasi_menit, j.jumlah_soal_ditampilkan,
                j.token_ujian, j.bank_soal_id,
                j.passing_grade, j.acak_soal, j.acak_jawaban,
                j.tampilkan_nilai_langsung, j.kode_ujian,
                (SELECT string_agg(c.name, ', ')
                 FROM cbt_jadwal_ujian_op_course_rel r
                 JOIN op_course c ON c.id = r.op_course_id
                 WHERE r.cbt_jadwal_ujian_id = j.id) as course_names
            FROM cbt_jadwal_ujian j
            LEFT JOIN op_subject mp ON mp.id = j.mata_pelajaran_id
            LEFT JOIN cbt_jenis_ujian ju ON ju.id = j.jenis_ujian_id
        """
        params = {}

        if course_id is not None:
            base_query += """
                JOIN cbt_jadwal_ujian_op_course_rel rel ON rel.cbt_jadwal_ujian_id = j.id
                WHERE j.active = TRUE AND rel.op_course_id = :course_id
            """
            params["course_id"] = course_id
        elif student_id is not None:
            base_query += """
                JOIN cbt_jadwal_ujian_op_course_rel rel ON rel.cbt_jadwal_ujian_id = j.id
                JOIN op_student_course sc ON sc.course_id = rel.op_course_id
                WHERE j.active = TRUE AND sc.student_id = :student_id
            """
            params["student_id"] = student_id
        else:
            base_query += " WHERE j.active = TRUE"

        base_query += " ORDER BY j.tanggal_mulai DESC, j.id DESC;"

        result = await self.db.execute(text(base_query), params)
        return [dict(row) for row in result.mappings().all()]

    async def get_schedule_by_id(self, jadwal_id: int) -> Optional[Dict[str, Any]]:
        query = text("""
            SELECT 
                j.id, j.name, j.token_ujian, j.durasi_menit,
                j.bank_soal_id, j.status, j.mata_pelajaran_id,
                mp.name AS mata_pelajaran_name,
                j.jenis_ujian_id, ju.name AS jenis_ujian_name,
                j.passing_grade, j.acak_soal, j.acak_jawaban,
                j.tampilkan_nilai_langsung, j.jumlah_soal_ditampilkan,
                j.tanggal_mulai, j.tanggal_selesai
            FROM cbt_jadwal_ujian j
            LEFT JOIN op_subject mp ON mp.id = j.mata_pelajaran_id
            LEFT JOIN cbt_jenis_ujian ju ON ju.id = j.jenis_ujian_id
            WHERE j.id = :jadwal_id
            LIMIT 1;
        """)
        result = await self.db.execute(query, {"jadwal_id": jadwal_id})
        row = result.mappings().first()
        return dict(row) if row else None

    async def get_questions_by_bank_id(self, bank_soal_id: int) -> List[Dict[str, Any]]:
        """Ambil soal beserta opsi jawabannya dalam 2 query (Mengatasi N+1 Query)."""
        # Ambil daftar soal ujian sesuai urutan tampilnya.
        query_soal = text("""
            SELECT id, bank_soal_id, mata_pelajaran_id, kelas_id, rombel_id, sequence, jenis_soal, pertanyaan, tingkat_kesulitan, bobot_nilai, active
            FROM cbt_soal
            WHERE bank_soal_id = :bank_soal_id AND active = TRUE
            ORDER BY sequence ASC, id ASC;
        """)
        res_soal = await self.db.execute(query_soal, {"bank_soal_id": bank_soal_id})
        soal_list = [dict(r) for r in res_soal.mappings().all()]
        if not soal_list:
            return []

        soal_ids = [s["id"] for s in soal_list]

        # Ambil semua opsi sekaligus untuk menghindari query per soal.
        query_opsi = text("""
            SELECT id, soal_id, kode, teks_jawaban, sequence
            FROM cbt_soal_jawaban
            WHERE soal_id = ANY(:soal_ids)
            ORDER BY sequence ASC, id ASC;
        """)
        res_opsi = await self.db.execute(query_opsi, {"soal_ids": soal_ids})
        all_options = [dict(o) for o in res_opsi.mappings().all()]

        # Kelompokkan opsi berdasarkan question_id untuk response bertingkat.
        options_by_soal: Dict[int, List[Dict[str, Any]]] = {}
        for opt in all_options:
            sid = opt["soal_id"]
            options_by_soal.setdefault(sid, []).append(opt)

        for soal in soal_list:
            soal["options"] = options_by_soal.get(soal["id"], [])

        return soal_list

    async def get_hasil_ujian(self, student_id: int, jadwal_id: Optional[int] = None) -> List[Dict[str, Any]]:
        query_str = """
            SELECT 
                h.id, h.jadwal_ujian_id, j.name AS judul_ujian,
                h.student_id, h.kelas_id, h.mata_pelajaran_id,
                mp.name AS mata_pelajaran_name,
                h.jenis_ujian_id, ju.name AS jenis_ujian_name,
                h.jumlah_soal, h.jumlah_benar, h.jumlah_salah,
                h.jumlah_tidak_dijawab, h.status, h.keterangan_kelulusan,
                h.waktu_mulai, h.waktu_selesai, h.nilai,
                h.durasi_pengerjaan, h.token_verified
            FROM cbt_hasil_ujian h
            LEFT JOIN cbt_jadwal_ujian j ON j.id = h.jadwal_ujian_id
            LEFT JOIN op_subject mp ON mp.id = h.mata_pelajaran_id
            LEFT JOIN cbt_jenis_ujian ju ON ju.id = h.jenis_ujian_id
            WHERE h.student_id = :student_id
        """
        params = {"student_id": student_id}
        if jadwal_id:
            query_str += " AND h.jadwal_ujian_id = :jadwal_id"
        query_str += " ORDER BY h.waktu_mulai DESC;"

        result = await self.db.execute(text(query_str), params)
        return [dict(row) for row in result.mappings().all()]

    async def create_hasil_ujian(self, data: dict) -> int:
        query = text("""
            INSERT INTO cbt_hasil_ujian (
                jadwal_ujian_id, student_id, kelas_id, mata_pelajaran_id,
                jenis_ujian_id, jumlah_soal, waktu_mulai, waktu_selesai,
                status, token_verified
            ) VALUES (
                :jadwal_ujian_id, :student_id, :kelas_id, :mata_pelajaran_id,
                :jenis_ujian_id, :jumlah_soal, :waktu_mulai, :waktu_selesai,
                :status, :token_verified
            ) RETURNING id;
        """)
        result = await self.db.execute(query, data)
        await self.db.commit()
        return result.scalar_one()

    async def create_jawaban_siswa(self, data: dict) -> int:
        query = text("""
            INSERT INTO cbt_jawaban_siswa (
                hasil_ujian_id, soal_id, jenis_soal, waktu_jawab,
                jawaban_pilihan_id, jawaban_text
            ) VALUES (
                :hasil_ujian_id, :soal_id, :jenis_soal, :waktu_jawab,
                :jawaban_pilihan_id, :jawaban_text
            ) RETURNING id;
        """)
        # Gunakan key alternatif jika data lama belum memiliki key utama.
        data.setdefault("jawaban_pilihan_id", None)
        data.setdefault("jawaban_text", None)

        result = await self.db.execute(query, data)
        await self.db.commit()
        return result.scalar_one()

    async def update_hasil_ujian(self, hasil_id: int, values: dict) -> bool:
        query = text("""
            UPDATE cbt_hasil_ujian
            SET jumlah_benar = :jumlah_benar,
                jumlah_salah = :jumlah_salah,
                jumlah_tidak_dijawab = :jumlah_tidak_dijawab
            WHERE id = :hasil_id;
        """)
        values["hasil_id"] = hasil_id
        result = await self.db.execute(query, values)
        await self.db.commit()
        return result.rowcount > 0

    async def get_correct_answers(self, bank_soal_id: int) -> Dict[int, int]:
        """Mengembalikan dict {soal_id: jawaban_pilihan_id_yang_benar}"""
        query = text("""
            SELECT j.soal_id, j.id AS correct_option_id
            FROM cbt_soal_jawaban j
            JOIN cbt_soal s ON s.id = j.soal_id
            WHERE s.bank_soal_id = :bank_soal_id AND j.is_benar = TRUE;
        """)
        result = await self.db.execute(query, {"bank_soal_id": bank_soal_id})
        return {row["soal_id"]: row["correct_option_id"] for row in result.mappings().all()}
