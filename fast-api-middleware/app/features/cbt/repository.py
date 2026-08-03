from app.core.odoo_client import OdooRPCClient
from typing import List, Dict, Any, Optional

class CbtRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def get_schedules(self, uid: int, password: str) -> List[Dict[str, Any]]:
        """
        Record Rule Odoo otomatis memfilter jadwal ujian yang ditujukan 
        untuk kelas/rombel siswa yang sedang login.
        """
        fields = [
            'name', 'status', 'mata_pelajaran_id',
            'tanggal_mulai', 'tanggal_selesai',
            'durasi_menit', 'jumlah_soal_ditampilkan',
            'token_ujian', 'bank_soal_id'
        ]

        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='cbt.jadwal.ujian',
            domain=[('active', '=', True)],
            fields=fields,
            order='tanggal_mulai desc, id desc'
        )
        return records

    def get_schedule_by_id(self, uid: int, password: str, jadwal_id: int) -> Optional[Dict[str, Any]]:
        fields = ['name', 'token_ujian', 'durasi_menit', 'bank_soal_id', 'status', 'mata_pelajaran_id']
        records = self.odoo.search_read(
            uid=uid,
            password=password,
            model='cbt.jadwal.ujian',
            domain=[('id', '=', jadwal_id)],
            fields=fields,
            limit=1
        )
        return records[0] if records else None

    def get_questions_by_bank_id(self, uid: int, password: str, bank_soal_id: int) -> List[Dict[str, Any]]:
        fields = ['sequence', 'jenis_soal', 'pertanyaan']
        soal_list = self.odoo.search_read(
            uid=uid,
            password=password,
            model='cbt.soal',
            domain=[('bank_soal_id', '=', bank_soal_id), ('active', '=', True)],
            fields=fields,
            order='sequence asc, id asc'
        )

        for soal in soal_list:
            opsi_list = self.odoo.search_read(
                uid=uid,
                password=password,
                model='cbt.soal.jawaban',
                domain=[('soal_id', '=', soal['id'])],
                fields=['kode', 'teks_jawaban'],
                order='sequence asc, id asc'
            )
            soal['options'] = opsi_list

        return soal_list

    def create_hasil_ujian(self, uid: int, password: str, data: dict) -> int:
        """Membuat record pengerjaan hasil ujian baru (cbt.hasil.ujian)"""
        return self.odoo.models.execute_kw(
            self.odoo.db, uid, password,
            'cbt.hasil.ujian', 'create',
            [data]
        )

    def create_jawaban_siswa(self, uid: int, password: str, data: dict) -> int:
        """Menyimpan record jawaban pilihan/essay siswa (cbt.jawaban.siswa)"""
        return self.odoo.models.execute_kw(
            self.odoo.db, uid, password,
            'cbt.jawaban.siswa', 'create',
            [data]
        )