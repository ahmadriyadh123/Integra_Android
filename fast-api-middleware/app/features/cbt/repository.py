import logging
from app.core.odoo_client import OdooRPCClient
from typing import List, Dict, Any, Optional

logger = logging.getLogger(__name__)


class CbtRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def get_schedules(
        self, uid: int, password: str,
        course_id: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        """
        Ambil jadwal ujian CBT.
        Filter via Many2many course_ids menggunakan dot-notation pada field
        course_ids di cbt.jadwal.ujian yang merujuk ke cbt_jadwal_ujian_op_course_rel.
        Gunakan sudo karena user portal tidak punya akses langsung.
        """
        fields = [
            'id', 'name', 'status', 'mata_pelajaran_id',
            'tanggal_mulai', 'tanggal_selesai',
            'durasi_menit', 'jumlah_soal_ditampilkan',
            'token_ujian', 'bank_soal_id', 'jenis_ujian_id',
            'passing_grade', 'acak_soal', 'acak_jawaban',
            'tampilkan_nilai_langsung', 'kode_ujian'
        ]

        # Filter berdasarkan course_id jika tersedia
        domain = [('active', '=', True)]
        if course_id is not None:
            # course_ids adalah Many2many field di cbt.jadwal.ujian
            domain.append(('course_ids', 'in', [course_id]))

        records = self.odoo.search_read(
            uid=uid, password=password,
            model='cbt.jadwal.ujian',
            domain=domain,
            fields=fields,
            order='tanggal_mulai desc, id desc'
        )
        return records

    def get_schedule_by_id(
        self, uid: int, password: str, jadwal_id: int
    ) -> Optional[Dict[str, Any]]:
        fields = [
            'id', 'name', 'token_ujian', 'durasi_menit',
            'bank_soal_id', 'status', 'mata_pelajaran_id',
            'passing_grade', 'acak_soal', 'acak_jawaban',
            'tampilkan_nilai_langsung', 'jumlah_soal_ditampilkan',
            'tanggal_mulai', 'tanggal_selesai', 'course_ids'
        ]
        records = self.odoo.search_read(
            uid=uid, password=password,
            model='cbt.jadwal.ujian',
            domain=[('id', '=', jadwal_id)],
            fields=fields,
            limit=1
        )
        return records[0] if records else None

    def get_questions_by_bank_id(
        self, uid: int, password: str, bank_soal_id: int
    ) -> List[Dict[str, Any]]:
        """Ambil soal dari bank soal beserta opsi jawabannya."""
        fields = [
            'id', 'sequence', 'jenis_soal', 'pertanyaan',
            'tingkat_kesulitan', 'bobot_nilai'
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
                order='sequence asc, id asc'
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
