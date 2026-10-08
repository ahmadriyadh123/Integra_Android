# Integra School Admin Web

Project frontend mandiri untuk mengelola daftar tenant sekolah melalui API
FastAPI pada `fast-api-middleware`. Source UI berada di project ini dan tidak
disajikan oleh backend.

## Menjalankan lokal

Pastikan backend sudah berjalan pada `http://127.0.0.1:8000` dan telah
dikonfigurasi dengan `SCHOOL_ADMIN_USERNAME` serta `SCHOOL_ADMIN_PASSWORD`.

```powershell
cd school-admin-web
npm install
Copy-Item .env.example .env
npm run dev
```

Buka URL lokal yang ditampilkan Vite, biasanya `http://localhost:5173`, lalu
masuk menggunakan kredensial admin backend. Proxy Vite meneruskan `/api/v1`
ke backend tanpa memerlukan konfigurasi CORS untuk development lokal. Untuk
backend lokal pada alamat lain, sesuaikan `VITE_API_PROXY_TARGET` di `.env`.

## Build dan hosting

```powershell
npm run build
npm run preview
```

Build statis dibuat di `dist/`. Secara default, aplikasi memanggil API pada
path `/api/v1`; hosting production sebaiknya merutekan path tersebut ke
FastAPI pada domain frontend yang sama. Jika API memakai origin HTTPS terpisah,
set `VITE_API_BASE_URL` sebelum build dan tambahkan exact origin web ini ke
`CORS_ALLOW_ORIGINS` backend. Web dan API harus berada pada site yang sama
(misalnya subdomain `admin.example.com` dan `api.example.com`) agar cookie
sesi admin `SameSite=Strict` dapat digunakan browser.

Autentikasi admin dikelola backend dan diverifikasi terhadap tabel
`school_admin_accounts`; project web tidak menyimpan kredensial. Pada startup
pertama, backend mengambil `SCHOOL_ADMIN_USERNAME` dan
`SCHOOL_ADMIN_PASSWORD` dari environment untuk membuat akun awal dengan
password salted PBKDF2-SHA256. Password awal wajib minimal 12 karakter dan
tidak pernah disimpan sebagai teks biasa. Bootstrap hanya membuat akun jika
tabel belum memiliki akun, sehingga mengubah nilai environment tidak mereset
password admin. Setelah pembuatan akun pertama, hapus password bootstrap dari
environment/secret konfigurasi. Simpan dan cadangkan database registry secara
aman; tabel tersebut berisi hash autentikasi admin.

Dashboard juga memeriksa koneksi setiap tenant ke endpoint Odoo XML-RPC
`common.version()`. Hasil menampilkan status, waktu respons, versi server jika
tersedia, dan pesan kegagalan yang aman. Pemeriksaan awal dilakukan setelah
login dan diulang setiap 60 detik; tombol **Periksa semua koneksi** menjalankan
pemeriksaan manual. Tombol refresh di setiap baris menguji koneksi sekolah
tersebut saja. Hasil pemeriksaan bersifat sementara di dashboard dan tidak
disimpan sebagai riwayat. Pemeriksaan ini memastikan layanan XML-RPC Odoo
merespons, tetapi tidak mengautentikasi database atau kredensial pengguna.
