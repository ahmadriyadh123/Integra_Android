# Panduan Odoo Pusat — Integra School Admin

Dokumen ini ditujukan untuk administrator server **Odoo pusat** yang
menyimpan daftar tenant sekolah dan mengirimkan data tenant ke registry
backend aplikasi mobile.

Addon yang digunakan:

```text
Integra School Admin
Technical name: integra_school_admin
```

## 1. Arsitektur

```text
Odoo pusat
  └─ addon integra_school_admin
       └─ HTTPS REST + JSON
            └─ Backend registry
                 └─ PostgreSQL: school_tenants
```

Addon dipasang pada **Odoo pusat**, bukan pada setiap database tenant sekolah.
Backend registry tetap menjadi sumber data untuk aplikasi mobile.

Sinkronisasi menggunakan endpoint:

```text
PUT /api/v1/admin/tenants/{school_code}
```

Autentikasi menggunakan header:

```text
X-Registry-Admin-Token
```

Komunikasi sinkronisasi ini bukan JSON-RPC. Fitur pemeriksaan koneksi tenant
yang tersedia di addon menggunakan XML-RPC Odoo pada endpoint tenant.

## 2. Prasyarat

Sebelum pemasangan, pastikan:

- Odoo pusat dapat dihentikan dan dimulai ulang oleh administrator.
- Versi Odoo yang digunakan mendukung view type `list` (Odoo 19).
- Server Odoo pusat dapat mengakses HTTPS backend registry.
- Backend registry sudah menyediakan endpoint admin tenant.
- Administrator backend memberikan nilai `REGISTRY_ADMIN_TOKEN` melalui
  saluran rahasia.
- Nilai token tidak disimpan di Git, tiket, screenshot, atau chat.
- Nama database tenant dan URL Odoo tenant sudah diketahui.

Jangan mengisi password database tenant pada addon. Gunakan `secret_ref_db`
sebagai referensi secret yang dikelola oleh backend/server.

## 3. Memasang addon

### 3.1. Salin addon ke addons path

Salin folder berikut ke salah satu direktori pada `addons_path` Odoo pusat:

```text
integra_school_admin
```

Contoh Windows:

```text
C:\Odoo\server\odoo\addons\integra_school_admin
```

Contoh Linux:

```text
/opt/odoo/custom-addons/integra_school_admin
```

Pastikan struktur minimalnya seperti berikut:

```text
integra_school_admin/
├── __init__.py
├── __manifest__.py
├── models/
│   ├── __init__.py
│   └── school_tenant.py
├── security/
│   └── ir.model.access.csv
└── views/
    └── school_tenant_views.xml
```

### 3.2. Restart Odoo

Restart wajib dilakukan setelah file Python addon baru disalin. Upgrade dari
antarmuka saja tidak cukup jika proses Odoo masih memuat registry Python lama.

Windows PowerShell sebagai Administrator:

```powershell
Restart-Service -Name "odoo-server-19.0" -Force
```

Linux:

```bash
sudo systemctl restart odoo
sudo systemctl status odoo --no-pager
```

### 3.3. Install atau upgrade dari Apps

1. Login ke database Odoo pusat.
2. Aktifkan Developer Mode.
3. Buka **Apps**.
4. Pilih **Update Apps List**.
5. Cari **Integra School Admin**.
6. Klik **Install** jika belum terpasang.
7. Klik **Upgrade** jika modul sudah terpasang.
8. Refresh browser menggunakan `Ctrl + F5`.

Menu yang tersedia:

```text
School Admin → Daftar sekolah
```

Menu tersebut hanya terlihat oleh pengguna dengan grup Administrator Odoo
(`base.group_system`).

## 4. Mengatur parameter registry backend

Pada Odoo pusat, buka:

```text
Settings → Technical → Parameters → System Parameters
```

Buat parameter berikut.

### URL backend registry

```text
Key:
integra_school_admin.registry_api_url

Value:
https://kp-sekolah.asetkoptii.com/mobile-api/api/v1
```

### Token admin registry

```text
Key:
integra_school_admin.registry_admin_token

Value:
TOKEN_REGISTRY_ADMIN
```

Nilai `TOKEN_REGISTRY_ADMIN` harus sama persis dengan:

```env
REGISTRY_ADMIN_TOKEN=TOKEN_REGISTRY_ADMIN
```

di environment backend registry.

Jika parameter URL tidak dibuat, addon menggunakan URL default yang sama.
Parameter token tetap wajib dibuat.

## 5. Mengisi data tenant

Buka:

```text
School Admin → Daftar sekolah → New
```

Isi field berikut:

| Field | Keterangan |
|---|---|
| Kode sekolah | Kode unik tenant, misalnya `TEST` |
| Nama sekolah | Nama sekolah tenant |
| URL Odoo | URL publik Odoo tenant, tanpa username/password |
| Database Odoo | Nama database tenant |
| Host PostgreSQL | Host database tenant sesuai konfigurasi server |
| Port PostgreSQL | Umumnya `5432` |
| User database | User database jika diperlukan oleh proses backend |
| Referensi secret database | Nama/referensi secret, bukan password |
| Aktif | Status tenant pada representasi lokal addon |

Aturan validasi:

- `school_code` otomatis diubah menjadi huruf besar.
- `school_code` harus unik.
- `odoo_db` harus unik.
- URL harus menggunakan `http://` atau `https://`.
- URL tidak boleh berisi username, password, query, atau fragment.
- Untuk koneksi tenant non-localhost, gunakan HTTPS.

Klik **Save** sebelum melakukan sinkronisasi.

## 6. Sinkronisasi ke registry backend

Setelah data tenant disimpan:

1. Buka kembali data tenant.
2. Klik **Sinkronkan registry**.
3. Tunggu notifikasi hasil operasi.
4. Periksa bagian **Status registry**.

Jika berhasil:

```text
Status: Tersinkron
Registry ID: terisi
Waktu sinkronisasi: terisi
```

Data yang dikirim:

```json
{
  "school_code": "TEST",
  "school_name": "Nama Sekolah",
  "odoo_url": "https://tenant.example.com",
  "odoo_db": "tenant_database",
  "is_active": true,
  "user_db": "user_backend",
  "secret_ref_db": "tenant-test",
  "odoo_db_host": "127.0.0.1",
  "odoo_db_port": 5432
}
```

Password database tenant tidak dikirim oleh addon.

## 7. Memeriksa koneksi Odoo tenant

Tombol **Periksa koneksi Odoo** hanya menguji respons endpoint:

```text
https://alamat-tenant/xmlrpc/2/common
```

Fitur ini berbeda dari sinkronisasi registry:

- **Periksa koneksi Odoo**: Odoo pusat → Odoo tenant, menggunakan XML-RPC.
- **Sinkronkan registry**: Odoo pusat → backend registry, menggunakan REST JSON.

Pastikan URL tenant dapat dijangkau dari server Odoo pusat, bukan hanya dari
komputer administrator.

## 8. Troubleshooting

### `Field "registry_sync_status" does not exist`

Python model belum dimuat ulang.

1. Pastikan file `models/school_tenant.py` terbaru sudah berada di addons path.
2. Restart service Odoo.
3. Upgrade addon.

### `401 Unauthorized`

Masalah ini berkaitan dengan token admin registry, bukan
`secret_ref_db`.

Periksa:

- Key parameter Odoo tepat:
  `integra_school_admin.registry_admin_token`.
- Nilai token Odoo sama dengan `REGISTRY_ADMIN_TOKEN` backend.
- Tidak ada spasi tambahan atau tanda kutip yang ikut menjadi bagian token.
- Backend sudah direstart setelah `.env` berubah.
- Nginx meneruskan header `X-Registry-Admin-Token`.
- URL mengarah ke backend yang benar.

Jangan mencetak token ke log. Untuk pemeriksaan server, cek hanya keberadaan
dan panjang token.

### `404 Not Found`

Periksa URL parameter dan route backend:

```text
https://kp-sekolah.asetkoptii.com/mobile-api/api/v1/admin/tenants/TEST
```

Pastikan prefix `/mobile-api` dan `/api/v1` tidak tertulis dua kali atau
terlewat.

### Timeout atau koneksi gagal

Periksa dari server Odoo pusat:

```bash
curl -I --max-time 15 https://kp-sekolah.asetkoptii.com/mobile-api/api/v1
```

Periksa DNS, firewall, sertifikat HTTPS, dan konfigurasi reverse proxy.

### Sinkronisasi gagal karena validasi payload

Pastikan:

- Kode sekolah tidak kosong.
- Nama sekolah tidak kosong.
- URL Odoo valid.
- Nama database tidak kosong.
- Host PostgreSQL tidak kosong.
- Port berada pada rentang `1` sampai `65535`.

## 9. Verifikasi administrator

Setelah konfigurasi, lakukan verifikasi berikut:

- [ ] Modul terlihat sebagai terpasang pada Apps.
- [ ] Menu **School Admin → Daftar sekolah** terlihat.
- [ ] Data tenant dapat dibuat dan disimpan.
- [ ] Tombol **Periksa koneksi Odoo** memberikan respons.
- [ ] Tombol **Sinkronkan registry** berhasil.
- [ ] Data tenant muncul pada tabel registry `school_tenants`.
- [ ] Aplikasi mobile dapat membaca tenant yang aktif.
- [ ] Token tidak muncul di log, Git, screenshot, atau dokumentasi publik.

## 10. Catatan keamanan

- Batasi akses menu addon kepada administrator yang diperlukan.
- Jangan mengirim password database tenant dari Odoo.
- Simpan token backend hanya pada secret manager atau file environment dengan
  permission ketat.
- Gunakan HTTPS untuk backend dan seluruh URL tenant produksi.
- Rotasi token jika pernah terekspos.
- Setelah rotasi token, ubah nilai pada backend dan parameter Odoo secara
  berurutan, lalu uji sinkronisasi.
