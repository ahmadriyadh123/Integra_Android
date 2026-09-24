import logging
from app.core.odoo_client import OdooRPCClient
from typing import List, Dict, Any, Optional

logger = logging.getLogger(__name__)


class CbtRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def get_schedules(
        self, uid: int, password: str,
        course_id: Optional[int] = None,
        student_id: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        """
        Ambil jadwal ujian CBT khusus kelas pengguna yang sedang login.
        """
        if not course_id and (student_id or uid):
            try:
                domain_student = [('id', '=', student_id)] if student_id else [('user_id', '=', uid)]
                records = self.odoo.search_read(
                    uid=uid, password=password,
                    model='op.student',
                    domain=domain_student,
                    fields=['grade'],
                    limit=1,
                    use_sudo=True
                )
                if records and records[0].get('grade'):
                    g = records[0]['grade']
                    if isinstance(g, list) and g:
                        course_id = int(g[0])
                    elif isinstance(g, int):
                        course_id = g
            except Exception as e:
                logger.warning(f"[cbt repository] Gagal mengambil grade/course_id siswa: {e}")

        fields = [
            'id', 'name', 'status', 'mata_pelajaran_id',
            'tanggal_mulai', 'tanggal_selesai',
            'durasi_menit', 'jumlah_soal_ditampilkan',
            'token_ujian', 'bank_soal_id', 'jenis_ujian_id',
            'passing_grade', 'acak_soal', 'acak_jawaban',
            'tampilkan_nilai_langsung', 'kode_ujian'
        ]

        domain = [('active', '=', True)]
        if course_id:
            domain.append(('kelas_ids', 'in', [course_id]))

        try:
            return self.odoo.search_read(
                uid=uid, password=password,
                model='cbt.jadwal.ujian',
                domain=domain,
                fields=fields,
                order='tanggal_mulai desc, id desc'
            )
        except Exception as e:
            if "doesn't exist" in str(e):
                logger.warning("[cbt repository] Model cbt.jadwal.ujian belum tersedia di Odoo")
                return []
            raise

    def get_schedule_by_id(
        self, uid: int, password: str, jadwal_id: int
    ) -> Optional[Dict[str, Any]]:
        fields = [
            'id', 'name', 'token_ujian', 'durasi_menit',
            'bank_soal_id', 'status', 'mata_pelajaran_id',
            'passing_grade', 'acak_soal', 'acak_jawaban',
            'tampilkan_nilai_langsung', 'jumlah_soal_ditampilkan',
            'tanggal_mulai', 'tanggal_selesai'
        ]
        try:
            records = self.odoo.search_read(
                uid=uid, password=password,
                model='cbt.jadwal.ujian',
                domain=[('id', '=', jadwal_id)],
                fields=fields,
                limit=1
            )
            return records[0] if records else None
        except Exception as e:
            if "doesn't exist" in str(e):
                logger.warning("[cbt repository] Model cbt.jadwal.ujian belum tersedia di Odoo")
                return None
            raise

    def get_questions_by_bank_id(
        self, uid: int, password: str, bank_soal_id: int
    ) -> List[Dict[str, Any]]:
        """
        Ambil soal dari bank soal (cbt.soal) beserta opsi jawabannya (cbt.soal.jawaban)
        menggunakan kredensial siswa (uid & password) agar sesuai dengan hak akses (ACL) siswa.
        """
        fields = [
            'id', 'bank_soal_id', 'mata_pelajaran_id', 'kelas_id', 'rombel_id',
            'sequence', 'jenis_soal', 'pertanyaan', 'tingkat_kesulitan',
            'bobot_nilai', 'active'
        ]
        soal_list = self.odoo.search_read(
            uid=uid, password=password,
            model='cbt.soal',
            domain=[('bank_soal_id', '=', bank_soal_id), ('active', '=', True)],
            fields=fields,
            order='sequence asc, id asc'
        )

        for soal in soal_list:
            opsi_list = self.odoo.search_read(
                uid=uid, password=password,
                model='cbt.soal.jawaban',
                domain=[('soal_id', '=', soal['id'])],
                fields=['id', 'kode', 'teks_jawaban', 'sequence'],
                order='sequence asc, id asc',
                use_sudo=True
            )
            soal['options'] = opsi_list

        return soal_list

    def get_hasil_ujian(
        self, uid: int, password: str,
        student_id: int, jadwal_id: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        """Ambil riwayat hasil ujian siswa."""
        fields = [
            'id', 'jadwal_ujian_id', 'student_id', 'kelas_id',
            'mata_pelajaran_id', 'jenis_ujian_id',
            'jumlah_soal', 'jumlah_benar', 'jumlah_salah',
            'jumlah_tidak_dijawab', 'status', 'keterangan_kelulusan',
            'waktu_mulai', 'waktu_selesai', 'nilai',
            'durasi_pengerjaan', 'token_verified'
        ]
        domain = [('student_id', '=', student_id)]
        if jadwal_id:
            domain.append(('jadwal_ujian_id', '=', jadwal_id))

        return self.odoo.search_read(
            uid=uid, password=password,
            model='cbt.hasil.ujian',
            domain=domain,
            fields=fields,
            order='waktu_mulai desc'
        )

    def create_hasil_ujian(
        self, uid: int, password: str, data: dict
    ) -> int:
        """Buat record hasil ujian baru."""
        return self.odoo.execute_kw(
            uid=uid, password=password,
            model='cbt.hasil.ujian',
            method='create',
            args=[data]
        )

    def create_jawaban_siswa(
        self, uid: int, password: str, data: dict
    ) -> int:
        """Simpan satu jawaban siswa."""
        return self.odoo.execute_kw(
            uid=uid, password=password,
            model='cbt.jawaban.siswa',
            method='create',
            args=[data]
        )

    def update_hasil_ujian(
        self, uid: int, password: str,
        hasil_id: int, values: dict
    ) -> bool:
        """Update record hasil ujian (waktu selesai, nilai, status)."""
        return self.odoo.execute_kw(
            uid=uid, password=password,
            model='cbt.hasil.ujian',
            method='write',
            args=[[hasil_id], values]
        )
