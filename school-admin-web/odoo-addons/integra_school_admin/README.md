# Integra School Admin Odoo Addon

Addon native untuk menyimpan direktori sekolah di database Odoo. Addon
menyediakan model sekolah, daftar dan form di menu **School Admin**, pengarsipan
sekolah, pembatasan akses untuk grup administrator bawaan Odoo, serta pemeriksaan
endpoint XML-RPC Odoo tanpa autentikasi database.

## Instalasi

1. Salin folder `integra_school_admin` ke direktori addons kustom pada server
   Odoo.
2. Pastikan direktori tersebut tercantum pada `addons_path` di konfigurasi Odoo.
3. Mulai ulang Odoo, perbarui daftar Apps, lalu instal **Integra School Admin**.
4. Pastikan pengguna Odoo pusat yang mengelola registry termasuk grup bawaan
   **Administration/Settings** (`base.group_system`).
5. Pastikan server Odoo pusat dapat menjangkau endpoint Odoo setiap sekolah
   jika fitur pemeriksaan koneksi digunakan.

Folder `integra_school_admin` sendiri adalah paket addon yang siap dipasang;
tidak perlu menyalin `school-admin-web`, `node_modules`, atau fixture npm ke
server Odoo. Jika distribusi dilakukan sebagai arsip, arsipkan folder
`integra_school_admin` sehingga folder tersebut menjadi direktori tingkat
atas di dalam arsip.

Database Odoo pusat menyimpan registry sekolah. `school-admin-web` dapat
memakai daftar ini untuk memilih tenant. Password akun tenant hanya dipakai
dalam request pemeriksaan koneksi dan tidak disimpan. Untuk arsitektur dan cara
menjalankan web admin, lihat
[`../../README.md`](../../README.md).

## Kompatibilitas

Model dan ACL memakai API inti Odoo yang lazim. Struktur view menggunakan
elemen `tree`/`tree,form`; validasi dan instalasi tetap harus dijalankan pada
versi mayor Odoo tujuan karena format view dapat berbeda antarversi. Jangan
anggap addon siap produksi atau lintas versi sebelum uji install, upgrade, dan
hak akses pada server target. Versi Odoo target belum ditentukan.

## Catatan operasional

- Pemeriksaan koneksi membuat request keluar dari server Odoo ke
  `odoo_url/xmlrpc/2/common`, dengan batas waktu 8 detik.
- Pemeriksaan hanya membuktikan endpoint XML-RPC merespons; tidak menguji
  database atau kredensial pengguna.
- URL tenant harus berupa HTTP/HTTPS yang valid. Jangan memasukkan kredensial
  ke dalam URL.
- Menu addon, registry sekolah, dan endpoint pusat hanya memakai
  grup administrator bawaan `base.group_system`; tidak diperlukan grup addon
  tambahan.
- Versi `1.2.0` menghapus menu **Konfigurasi Model** dari instalasi versi lama.
  Upgrade addon pada Odoo pusat agar menu lama ikut dibersihkan.
- Kode sekolah dinormalisasi menjadi huruf besar dan unik. Status nonaktif
  menggunakan mekanisme arsip Odoo.
- Menu **Konfigurasi Model** tidak ditampilkan; addon kembali fokus pada
  pengelolaan daftar sekolah dan koneksi Odoo.
- Jalankan tes addon dengan `odoo-bin --addons-path=<addons_path> -d <database>
  -i integra_school_admin --test-enable --stop-after-init`.
- Fixture npm untuk pengujian format direktori server tersedia di
  `../../test/fixtures/odoo-tenant-directory.json`; fixture tersebut tidak
  digunakan oleh Odoo dan tidak mengandung kredensial.
