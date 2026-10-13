# Integra School Admin Odoo Addon

Addon native untuk menyimpan direktori sekolah di database Odoo. Addon
menyediakan model sekolah, daftar dan form di menu **School Admin**, pengarsipan
sekolah, pembatasan akses untuk grup administrator bawaan Odoo, serta pemeriksaan
endpoint XML-RPC Odoo tanpa autentikasi database. Menu **Konfigurasi Model**
memungkinkan administrator memilih satu konfigurasi per model, daftar field
model tersebut, field relasional, dan field pada model tujuan relasi.

## Instalasi

1. Salin folder `integra_school_admin` ke direktori addons kustom pada server
   Odoo.
2. Pastikan direktori tersebut tercantum pada `addons_path` di konfigurasi Odoo.
3. Mulai ulang Odoo, perbarui daftar Apps, lalu instal **Integra School Admin**.
4. Pastikan pengguna Odoo pusat yang mengelola registry termasuk grup bawaan
   **Administration/Settings** (`base.group_system`).
5. Pasang addon pada setiap database tenant sekolah. Akun yang digunakan
   membaca konfigurasi tenant juga harus termasuk grup **Administration/Settings**
   bawaan Odoo.

Database Odoo pusat menyimpan registry sekolah; setiap database tenant
menyimpan konfigurasi modelnya masing-masing. `school-admin-web` login ke Odoo
pusat untuk memilih tenant. Odoo pusat kemudian mengautentikasi akun
administrator tenant melalui XML-RPC dan membaca konfigurasi model, field,
serta relasi. Password akun tenant hanya dipakai dalam request dan tidak disimpan. Untuk
arsitektur dan cara menjalankan web admin, lihat
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
- Pembacaan konfigurasi tenant membutuhkan HTTPS. Jangan gunakan akun portal
  siswa; gunakan akun internal dalam grup bawaan **Administration/Settings**
  (`base.group_system`).
- Menu addon, registry sekolah, konfigurasi, dan endpoint pusat hanya memakai
  grup administrator bawaan `base.group_system`; tidak diperlukan grup addon
  tambahan.
- Versi `1.1.0` mencakup migrasi yang membersihkan grup dan ACL custom dari
  versi addon sebelumnya. Upgrade addon pada Odoo pusat dan setiap tenant.
- Kode sekolah dinormalisasi menjadi huruf besar dan unik. Status nonaktif
  menggunakan mekanisme arsip Odoo.
- Konfigurasi metadata hanya menyimpan pilihan model/field; addon ini belum
  menerapkannya sebagai pemetaan atau hak akses untuk aplikasi lain.
- Jalankan tes addon dengan `odoo-bin --addons-path=<addons_path> -d <database>
  -i integra_school_admin --test-enable --stop-after-init`.
