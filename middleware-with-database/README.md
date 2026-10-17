# Middleware Direct Database

## Konfigurasi URL API untuk Flutter

Aplikasi Flutter terbaru mengambil URL API saat startup dari endpoint
`GET /client-config` dan menyimpan URL terakhir sebagai fallback offline.
Endpoint bootstrap tetapnya adalah
`https://kp-sekolah.asetkoptii.com/mobile-api/client-config`.

Atur URL layanan yang sedang aktif pada environment backend:

```env
CLIENT_API_BASE_URL=https://kp-sekolah.asetkoptii.com/mobile-api/api/v1
```

Nilai tersebut harus berupa URL HTTPS yang berakhir dengan `/api/v1`.
Setelah mengubahnya, restart service backend. Aplikasi Play Store perlu
mendapat satu kali pembaruan untuk mulai menggunakan konfigurasi remote;
versi lama yang belum memiliki bootstrap ini tetap memakai URL yang dibangun
ke dalam aplikasinya. Untuk pengembangan, `--dart-define=API_BASE_URL=...`
tetap menjadi override eksplisit dan melewati konfigurasi remote.

Backend ini membaca data sekolah langsung melalui SQLAlchemy async. Database
registry menyimpan daftar sekolah, sedangkan setiap sekolah menunjuk ke database
Odoo terpisah melalui host dan port PostgreSQL miliknya sendiri. Tidak ada
pemanggilan JSON-RPC.

## Konfigurasi

Salin `.env.example` menjadi `.env`, lalu atur kredensial PostgreSQL dan secret
JWT. `REGISTRY_DB_NAME` adalah database pusat yang harus dibuat sebelum backend
dijalankan. Role PostgreSQL pada environment digunakan untuk registry dan koneksi
tenant; untuk kredensial tenant yang berbeda, atur `TENANT_SECRETS_FILE` ke file
JSON yang hanya dapat dibaca service backend. Jika service berjalan sebagai
`devmobile`, gunakan lokasi privat milik akun tersebut (contoh untuk testing:
`/home/devmobile/tenant-secrets-testing.json`) dan permission
`600`. Jangan gunakan file testing untuk service produksi.
Pastikan host tenant dapat
dijangkau dari server middleware, firewall dan `pg_hba.conf` mengizinkan koneksi,
serta role tersebut memiliki izin ke database sekolah.
Jika file Odoo memakai filestore, `ODOO_FILESTORE_PATH` harus menunjuk ke root
filestore bersama dengan susunan `<database-sekolah>/<store_fname>`.
Attachment SCORM publik juga dapat diambil backend melalui endpoint HTTP Odoo
`/web/content/<attachment_id>?download=true`; fallback ini tidak memakai
JSON-RPC. Attachment privat tetap memerlukan filestore yang dapat diakses backend.
Progres E-Learning dibaca dan disimpan per peserta pada tabel
`slide_slide_partner`, lalu dikaitkan ke materi dan course tenant yang sama.
Dokumen/video ditandai selesai ketika dibuka; SCORM hanya saat player melaporkan
`completed` atau `passed`. Persentase course memakai jumlah materi terbit.
E-Rapor dibaca langsung dari database tenant melalui SQLAlchemy, termasuk
varian tabel STS lama dan ledger SD/SMP/TK. Endpoint mendukung daftar, delta
sync berbasis `write_date`, detail nilai, serta unduh PDF dari attachment
database/filestore atau dari template Word E-Rapor saat lampiran tidak ada.
Pembuatan PDF dari template memerlukan `docxtpl` dan executable LibreOffice
(`soffice` atau `libreoffice`) pada lingkungan server.
Pengumpulan tugas menerima satu atau beberapa lampiran dalam satu submit;
setiap file dibatasi maksimal 20 MiB dan seluruh lampiran ditautkan ke satu
submission siswa.
Buku Komunikasi membaca dan memperbarui tabel tenant `bukpeng_<jenjang>` /
`bukpeng_<jenjang>_line` secara langsung. Catatan dan feedback dibatasi ke buku
milik siswa pada token aktif; catatan pekan baru dapat dibuat dengan `line_id`
0 beserta bulan dan pekan.

Saat startup, tabel `school_tenants` dibuat di database registry jika belum ada,
dengan kolom yang sama seperti daftar tenant yang digunakan admin: `id`,
`school_code`, `school_name`, `odoo_url`, `odoo_db`, `is_active`, `user_db`,
`secret_ref_db`, `odoo_db_host`, dan `odoo_db_port`. `odoo_url` adalah URL HTTP
Odoo; `odoo_db_host` dan `odoo_db_port` adalah alamat PostgreSQL sekolah;
`odoo_db` adalah nama katalog database PostgreSQL. `user_db` menyimpan username
database bila diperlukan untuk integrasi secret per tenant, sedangkan
`secret_ref_db` hanya menyimpan referensi secret, bukan password.

Format file `TENANT_SECRETS_FILE`:

```json
{
  "tenant/bogor/postgresql": {
    "username": "mwd_bogor",
    "password": "diisi-admin-server"
  }
}
```

File tersebut harus dibuat dan dikelola admin server dengan permission minimum
yang memungkinkan service membacanya. Password tenant tidak dimasukkan ke
registry, Git, atau respons API.
Tambahkan data yang diberikan ke registry yang kosong, misalnya:

```sql
INSERT INTO school_tenants
    (id, school_code, school_name, odoo_url, odoo_db_host, odoo_db_port,
     odoo_db, is_active)
VALUES
    (1, 'TEST APK', 'test', 'https://kp-sekolah.asetkoptii.com',
     '10.20.30.40', 5432, '<nama_database_postgresql_odoo_test>', TRUE),
    (2, 'SEKOLAH-001', 'Sekolah Alam Bogor',
     'https://sekolahalambogor.sch.id', '10.20.30.41', 5432,
     '<nama_database_postgresql_odoo_sekolah_alam_bogor>', TRUE);
```

Kolom `odoo_db` harus persis sama dengan nama database sekolah yang sudah ada
pada `odoo_db_host:odoo_db_port`.
Jangan mengisi `odoo_db` dengan URL/domain sekolah kecuali memang itulah nama
database PostgreSQL-nya. Database registry tidak boleh dipakai sebagai
database tenant.

## Pemilihan tenant

- `GET /api/v1/auth/schools` menampilkan sekolah aktif dan tidak membutuhkan
  header tenant.
- Login dan endpoint tenant lainnya memerlukan `X-School-ID: <id>`.
- Login menghasilkan JWT yang terikat pada sekolah tersebut. Request yang
  membawa token untuk sekolah berbeda ditolak dengan HTTP 403.
- Setiap request tenant membuka sesi SQLAlchemy ke host, port, dan database
  sekolah terpilih. Engine dan connection pool digunakan ulang per kombinasi
  host, port, dan nama database.

Endpoint sinkronisasi presensi (`/api/v1/attendance/history/sync`) dan jadwal
CBT (`/api/v1/cbt/schedules/sync`) mengembalikan snapshot penuh untuk sekolah
dan siswa/kelas pada token aktif. Klien menerima cursor untuk kompatibilitas
kontrak, tetapi backend saat ini mengirim ulang snapshot pada setiap sinkronisasi.

Contoh alur:

```text
GET  /api/v1/auth/schools
POST /api/v1/auth/login          X-School-ID: 1
GET  /api/v1/profile/me          X-School-ID: 1, Authorization: Bearer <token>
```

Untuk menjalankan backend dari direktori ini:

```powershell
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
