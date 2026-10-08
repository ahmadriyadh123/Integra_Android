# Middleware Direct Database

Backend ini membaca data sekolah langsung melalui SQLAlchemy async. Database
registry menyimpan daftar sekolah, sedangkan setiap sekolah menunjuk ke database
Odoo terpisah pada server PostgreSQL yang sama. Tidak ada pemanggilan JSON-RPC.

## Konfigurasi

Salin `.env.example` menjadi `.env`, lalu atur kredensial PostgreSQL dan secret
JWT. `REGISTRY_DB_NAME` adalah database pusat yang harus dibuat sebelum backend
dijalankan. Pengguna PostgreSQL yang sama harus memiliki izin membaca database
registry dan setiap database sekolah.
Jika file Odoo memakai filestore, `ODOO_FILESTORE_PATH` harus menunjuk ke root
filestore bersama dengan susunan `<database-sekolah>/<store_fname>`.
Attachment SCORM publik juga dapat diambil backend melalui endpoint HTTP Odoo
`/web/content/<attachment_id>?download=true`; fallback ini tidak memakai
JSON-RPC. Attachment privat tetap memerlukan filestore yang dapat diakses backend.
Progres E-Learning dibaca dan disimpan per peserta pada tabel
`slide_slide_partner`, lalu dikaitkan ke materi dan course tenant yang sama.
Dokumen/video ditandai selesai ketika dibuka; SCORM hanya saat player melaporkan
`completed` atau `passed`. Persentase course memakai jumlah materi terbit.

Saat startup, tabel `school_tenants` dibuat di database registry jika belum ada,
dengan kolom yang sama seperti daftar tenant yang digunakan admin: `id`,
`school_code`, `school_name`, `odoo_url`, `odoo_db`, dan `is_active`. `odoo_url`
disimpan sebagai identitas sekolah; koneksi SQL tenant memakai host dan user
PostgreSQL bersama dari environment, lalu memilih database dari `odoo_db`.
Tambahkan data yang diberikan ke registry yang kosong, misalnya:

```sql
INSERT INTO school_tenants
    (id, school_code, school_name, odoo_url, odoo_db, is_active)
VALUES
    (1, 'TEST APK', 'test', 'https://kp-sekolah.asetkoptii.com',
     'kp-sekolah.asetkoptii.com', TRUE),
    (2, 'SEKOLAH-001', 'Sekolah Alam Bogor',
     'https://sekolahalambogor.sch.id',
     'sekolahalambogor.sch.id', TRUE);
```

Kolom `odoo_db` harus persis sama dengan nama database sekolah yang sudah ada.
Database registry tidak boleh dipakai sebagai database tenant.

## Pemilihan tenant

- `GET /api/v1/auth/schools` menampilkan sekolah aktif dan tidak membutuhkan
  header tenant.
- Login dan endpoint tenant lainnya memerlukan `X-School-ID: <id>`.
- Login menghasilkan JWT yang terikat pada sekolah tersebut. Request yang
  membawa token untuk sekolah berbeda ditolak dengan HTTP 403.
- Setiap request tenant membuka sesi SQLAlchemy ke database sekolah terpilih.
  Engine dan connection pool digunakan ulang per nama database.

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
