# Integra School Admin Web

Panel admin mandiri untuk mengelola registry tenant sekolah dan menu data yang
dipetakan ke model, field, filter, urutan, batas record, serta relasi Odoo.
Registry dan konfigurasi disimpan di server web
(JSON), bukan di database Odoo dan bukan di browser. Addon
`integra_school_admin` tidak diperlukan atau dipasang untuk menggunakan panel
ini.

Panel dapat meminta metadata model dan field langsung dari Odoo tenant melalui
server web, lalu mempratinjau record sesuai model, field, filter, pengurutan,
batas, dan relasi yang disimpan. Kredensial tenant hanya dikirim saat discovery
atau pratinjau; kredensial tidak disimpan. Pemetaan yang disimpan belum otomatis
mengubah pipeline data fitur lain di aplikasi.

## Menjalankan lokal

Prasyarat: Node.js 20.19+ atau 22.12+ dan npm.

```powershell
cd school-admin-web
npm install
$env:SCHOOL_ADMIN_PASSWORD = "ganti-dengan-password-admin-yang-kuat"
npm run dev
```

Buka alamat Vite yang ditampilkan di terminal (biasanya
`http://localhost:5173`). Perintah `dev` menjalankan server API dan Vite
bersamaan. Password admin panel harus dikonfigurasi melalui environment;
aplikasi sengaja tidak membaca file `.env`.

Pengaturan opsional:

| Variabel | Default | Keterangan |
| --- | --- | --- |
| `SCHOOL_ADMIN_PASSWORD` | — | Wajib untuk login panel. Gunakan password kuat dan rahasiakan. |
| `SCHOOL_ADMIN_HOST` | `127.0.0.1` | Alamat bind server API/produksi. |
| `SCHOOL_ADMIN_API_PORT` | `4174` | Port API saat development; Vite meneruskan `/api` ke port ini. |
| `PORT` | `4174` | Port server API/produksi. |
| `SCHOOL_ADMIN_DATA_FILE` | `data/configuration.json` | Lokasi file data relatif ke direktori aplikasi, atau path absolut. |

Data tenant dan konfigurasi fitur tersimpan di `school-admin-web/data/` secara
default dan diabaikan oleh Git. Lindungi file tersebut dan buat backup sesuai
kebijakan operasional. File memuat URL/database tenant dan pemetaan konfigurasi,
tetapi tidak memuat password Odoo.

## Mengelola tenant dan konfigurasi

1. Masuk memakai password panel (`SCHOOL_ADMIN_PASSWORD`).
2. Tambahkan kode, nama sekolah, URL Odoo, dan nama database tenant.
3. Pilih tenant, lalu buat menu data.
4. Untuk menemukan model/field, masukkan login dan password Odoo tenant ketika
   diminta. Akun tersebut perlu memiliki hak Odoo untuk membaca metadata
   `ir.model` dan `ir.model.fields`.
5. Pilih model dan field, lalu tentukan field judul, pengurutan, batas record,
   filter opsional, serta field relasi dan field tujuan.
6. Simpan menu. Gunakan **Pratinjau data** pada menu dan masukkan kredensial
   Odoo tenant yang berhak membaca model tersebut untuk melihat hasil query.

Operator filter yang tersedia: `=`, `!=`, `>`, `>=`, `<`, `<=`, `like`,
`ilike`, `in`, dan `not in`. Beberapa filter digabung sebagai kondisi AND.
Jumlah record pratinjau dibatasi 1–500; field relasi tambahan dibatasi 1.000
record per relasi.

Untuk tenant non-localhost, URL wajib HTTPS. Request discovery dan pratinjau dilakukan
server-ke-server, jadi browser tidak perlu akses lintas-origin atau konfigurasi
CORS di Odoo tenant. Server web harus dapat menjangkau URL Odoo tenant.

Pratinjau mengikuti hak akses record dan model akun yang digunakan. Gunakan
akun tenant dengan hak baca minimum yang sesuai, karena admin panel dapat
menampilkan data yang dapat diakses akun tersebut.

## Build dan production

```powershell
npm run build
$env:SCHOOL_ADMIN_PASSWORD = "password-admin-yang-kuat"
npm start
```

Build menghasilkan aset di `dist/`; server Node menyajikan UI dan API pada port
`4174` secara default. Untuk diakses dari perangkat lain, atur
`SCHOOL_ADMIN_HOST` sesuai jaringan dan tempatkan server di belakang HTTPS
reverse proxy dengan kontrol akses jaringan yang sesuai. Jangan mengekspos
server langsung ke internet tanpa HTTPS dan pengamanan deployment.

`npm run preview` hanya untuk memeriksa build frontend; gunakan `npm start`
untuk mencoba alur lengkap karena API tetap diperlukan. Endpoint
`/api/health` dapat digunakan untuk pemeriksaan kesehatan.

## Addon Odoo terdahulu

Direktori `odoo-addons/integra_school_admin` adalah custom addon yang dapat
disalin langsung ke `addons_path` Odoo untuk mengelola daftar server Odoo
sekolah pada database pusat. Addon menyimpan kode sekolah, nama sekolah, URL
Odoo, nama database, status aktif, dan konfigurasi model/relasi. Petunjuk
instalasi dan pengujian ada di
[`odoo-addons/integra_school_admin/README.md`](odoo-addons/integra_school_admin/README.md).

Salinan data untuk pengujian npm ada di
[`test/fixtures/odoo-tenant-directory.json`](test/fixtures/odoo-tenant-directory.json).
Jalankan validasinya dengan:

```powershell
npm test
```

Fixture hanya berisi URL dan database contoh; tidak berisi password atau
kredensial Odoo.
