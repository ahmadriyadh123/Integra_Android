# Panduan Deployment Backend MWD

Panduan tahap demi tahap untuk men-deploy backend FastAPI Middleware Direct
Database ke server Ubuntu yang sudah menjalankan PostgreSQL, Odoo, dan Nginx.
Dokumen ini hanya membahas backend dan operasional server.

## Batasan dan asumsi

- Target: Ubuntu 22.04, akun deployment `devmobile`, direktori aplikasi
  `/srv/developer/mwd`.
- PostgreSQL, database registry, database tenant Odoo, Odoo filestore, DNS,
  Nginx, dan sertifikat HTTPS dikelola oleh pemilik/admin server.
- Backend menggunakan database registry dan tenant yang sudah ada. Panduan
  ini tidak membuat, memigrasikan, atau menghapus database Odoo.
- Backend tidak boleh memiliki akses tulis ke filestore. Berikan baca/traverse
  minimum sesuai tenant yang diperlukan.
- Backend listen pada `127.0.0.1:8000`. Jangan membuka port 8000 ke internet;
  akses eksternal harus melalui Nginx/HTTPS.
- Kredensial, private key, token, dan isi `.env` tidak boleh dimasukkan ke Git,
  log yang dibagikan, tiket, atau chat.
- Pembuatan PDF dari template DOCX memerlukan LibreOffice Writer (`soffice`).
  Paket sistem ini harus dipasang oleh admin server; akun deployment tidak
  memiliki `sudo`.
- Beberapa langkah (ACL filestore, Nginx, linger, firewall, system service,
  rotasi PostgreSQL) memerlukan hak admin. Akun `devmobile` tidak memiliki
  `sudo`, jadi admin harus menjalankan bagian tersebut.
- Dokumen ini bukan jaminan high availability. Satu VM dengan satu proses
  backend tetap merupakan satu titik kegagalan. Backup, pemulihan, monitoring,
  kapasitas, dan pemulihan bencana harus disepakati dengan admin.

## Status server terakhir yang diketahui

Status ini berdasarkan pemeriksaan terakhir pada 14 Oktober 2026; cek ulang
sebelum menjalankan perubahan:

- Ubuntu 22.04; root disk 20 GB dengan sekitar 10 GB tersedia pada pemeriksaan
  tersebut.
- PostgreSQL, Nginx, dan Odoo 16 pernah terverifikasi aktif.
- Source dan virtual environment tersedia di `/srv/developer/mwd`.
- Database registry `kp-sekolah.asetkoptii.com` pernah terverifikasi dapat
  diakses oleh kredensial backend; tabel `school_tenants` sudah ada.
- Akses baca root filestore
  `/opt/odoo16/.local/share/Odoo/filestore` pernah terverifikasi.
- Service user `mwd-api` pernah `enabled` dan backend pernah berhasil
  menyajikan endpoint lokal.
- `Linger=no` pada pemeriksaan terakhir. Service user belum terjamin berjalan
  setelah logout atau boot.
- Pemeriksaan endpoint publik terakhir mendapat HTTP 502 dan status/listener
  service tidak konsisten. Anggap deployment **belum sehat untuk produksi**
  sampai semua verifikasi di bagian akhir lulus.

## Tahap 1 — Periksa ketersediaan dan prasyarat server

Login ke server:

```bash
ssh devmobile@kp-sekolah.asetkoptii.com
```

Periksa OS, resource, DNS, service, dan listener:

```bash
cat /etc/os-release
df -h /
free -h
getent ahostsv4 kp-sekolah.asetkoptii.com
systemctl is-active nginx
systemctl is-active postgresql
systemctl is-active odoo16
pg_isready -h 127.0.0.1 -p 5432
ss -ltn
curl -I --max-time 10 https://kp-sekolah.asetkoptii.com/
```

Sebelum deployment, pastikan:

1. Disk dan memori mencukupi; kapasitas harus dipantau karena Odoo, PostgreSQL,
   backup, dan log berbagi disk yang sama.
2. DNS domain menuju IP server dan HTTPS valid.
3. PostgreSQL menerima koneksi backend dan role aplikasi dapat membuka registry
   serta database tenant yang dibutuhkan.
4. Python 3, `venv`, `pip`, dan utilitas yang dipakai tersedia:

   ```bash
   python3 --version
   python3 -m venv --help
   command -v pip3
   ```

5. Backend hanya listen di loopback; firewall tidak mengekspos `8000`.
6. Jika fitur PDF Weekly Plan/E-Rapor digunakan, minta admin memasang
   LibreOffice Writer lalu pastikan executable tersedia:

   ```bash
   sudo apt-get update
   sudo apt-get install -y libreoffice-writer
   command -v soffice || command -v libreoffice
   ```

> Pada pemeriksaan terdahulu PostgreSQL listen pada `0.0.0.0:5432` dan
> `[::]:5432`. Minta admin mengaudit firewall dan `pg_hba.conf`, lalu batasi
> sumber koneksi PostgreSQL. Jangan mengubah firewall melalui SSH sebelum
> memastikan port SSH tetap diizinkan.

## Tahap 2 — Siapkan atau perbarui source

Direktori deployment:

```text
/srv/developer/mwd
```

Untuk upload dari PowerShell Windows, jalankan dari folder proyek backend.
Arsip ini mengecualikan `.env`, virtual environment, cache, dan Git:

```powershell
Set-Location C:\path\ke\project\middleware-with-database
$archive = Join-Path $env:TEMP 'mwd-source.tar.gz'
tar.exe -czf $archive `
  --exclude=.env `
  --exclude=.venv `
  --exclude=venv `
  --exclude=.git `
  --exclude=__pycache__ `
  --exclude=.pytest_cache `
  -C . .
scp $archive devmobile@kp-sekolah.asetkoptii.com:/home/devmobile/mwd-source.tar.gz
ssh devmobile@kp-sekolah.asetkoptii.com `
  "mkdir -p /srv/developer/mwd; tar -xzf /home/devmobile/mwd-source.tar.gz -C /srv/developer/mwd; rm -f /home/devmobile/mwd-source.tar.gz"
Remove-Item -LiteralPath $archive
```

Ganti `C:\path\ke\project` dengan path checkout yang benar. Ekstraksi
memperbarui source; perintah tersebut tidak menghapus file lama yang tidak ada
di arsip. Sebelum deploy versi baru:

1. Pastikan perubahan sudah diuji pada lingkungan pengembangan/staging.
2. Pastikan backup dan prosedur rollback tersedia.
3. Jangan pernah menyertakan `.env`, virtual environment Windows, atau secret
   dalam arsip.

### Deployment otomatis dan pemilihan backend

Workflow `.github/workflows/deploy-mwd.yml` dapat mendeploy kedua backend dari
repository yang sama:

- `fast-api-middleware`: integrasi Odoo melalui XML-RPC.
- `middleware-with-database`: akses tenant langsung melalui PostgreSQL.

Saat perubahan hanya menyentuh salah satu folder backend di branch `main`,
workflow memilih backend yang berubah secara otomatis. Jika kedua folder
backend berubah sekaligus, jalankan workflow manual dari **Actions → Deploy
MWD backend → Run workflow**, lalu pilih backend pada input `backend`.
Workflow menjalankan tes backend terpilih sebelum mengirim source ke server.

Keduanya memakai direktori dan service aktif yang sama (`/srv/developer/mwd`
dan `mwd-api`), sehingga deployment mengganti backend yang melayani URL publik.
Konfigurasi backend dapat disediakan dengan salah satu dari dua cara berikut:

1. **GitHub Actions Secrets (opsional):** isi `FAST_API_MIDDLEWARE_ENV` dan/atau
   `MWD_DATABASE_ENV` dengan seluruh konfigurasi `.env` produksi backend
   terkait. Workflow mengirim konfigurasi terpilih melalui SSH dan menghapus
   salinan sementara dari runner/server setelah deployment.
2. **File konfigurasi server (fallback):**
   `/srv/developer/mwd-env/fast-api-middleware.env` dan
   `/srv/developer/mwd-env/middleware-with-database.env`. Buat file sesuai
   `.env.example` masing-masing backend dengan izin ketat dan beri akun
   deployment izin baca.

Jika secret untuk backend terpilih terisi, nilainya digunakan; jika tidak,
workflow memakai file konfigurasi server yang sesuai. Jangan menyimpan `.env`
atau rahasia di source Git. Workflow memasang konfigurasi terpilih sebagai
`/srv/developer/mwd/.env`, yang dibaca systemd, menyimpan konfigurasi aktif
sebelumnya dalam backup berizin ketat, dan memulihkannya jika health check
server gagal.

Konfigurasi `FAST_API_MIDDLEWARE_ENV` harus memuat `REGISTRY_DB_HOST`,
`REGISTRY_DB_PORT`, `REGISTRY_DB_NAME`, `REGISTRY_DB_USER`,
`REGISTRY_DB_PASSWORD`, dan `JWT_SECRET_KEY`, sesuai
`fast-api-middleware/.env.example`. Fast API Middleware memakai JSON-RPC untuk
mengakses Odoo, sedangkan PostgreSQL registry dipakai untuk membaca tenant
sekolah. Pengaturan `DATABASE_URL`/`DB_USER`/`DB_PASSWORD` pada bagian
konfigurasi database di bawah berlaku untuk backend
`middleware-with-database`; jangan gunakan `DATABASE_URL` untuk Fast API
Middleware.

Sebelum mengaktifkannya:

1. Tambahkan repository secrets `DEPLOY_HOST` (hostname saja),
   `DEPLOY_USER` (akun deployment), `DEPLOY_SSH_KEY` (private key deployment),
   dan `DEPLOY_KNOWN_HOSTS` (host key yang fingerprint-nya sudah diverifikasi
   melalui kanal tepercaya) di **Settings → Secrets and variables → Actions**.
2. Untuk konfigurasi via file server, pastikan akun dapat membaca file
   environment backend yang dipilih. Untuk konfigurasi via GitHub Secrets,
   tambahkan `FAST_API_MIDDLEWARE_ENV` dan/atau `MWD_DATABASE_ENV` sesuai
   format `.env` backend, tanpa tanda kutip pembungkus. Selain itu akun harus
   dapat memperbarui `/srv/developer/mwd`, menjalankan
   `systemctl --user restart mwd-api`, dan membaca
   `/srv/developer/mwd/.venv`.
3. Pastikan `rsync`, `curl`, dan `tar` tersedia, service `mwd-api` aktif, dan
   kebijakan server mengizinkan akun deployment memasang dependency Python
   pada virtual environment bersama. Admin juga harus memasang LibreOffice
   Writer (`soffice` atau `libreoffice`) bila fitur PDF memerlukannya.
4. Jalankan workflow manual dahulu dari branch `main` dan verifikasi backend
   aktif serta fungsi API setelah deployment. Push source hanya memulai
   workflow; workflow gagal jika pemilihan backend ambigu.

Workflow membuat backup source di `~/mwd-deploy-backups/`, mempertahankan
virtual environment, memasang environment backend terpilih, dan memulihkan
source serta environment aktif sebelumnya jika health check lokal gagal.
Workflow tidak menjalankan migrasi database atau tes API dengan token pengguna.
Pantau kapasitas disk dan bersihkan backup lama sesuai kebijakan retensi.

## Tahap 3 — Siapkan Python environment dan dependency

Langkah membuat virtual environment dan memasang `requirements.txt` berlaku
untuk kedua backend. Fast API Middleware memerlukan akses PostgreSQL untuk
registry tenant sekolahnya melalui konfigurasi `REGISTRY_DB_*`. Pemeriksaan
dan konfigurasi database pada Tahap 4–5 di bawah menjelaskan koneksi backend
`middleware-with-database`, yang tetap memakai konfigurasi berbeda.

Di server:

```bash
cd /srv/developer/mwd
python3 -m venv .venv
.venv/bin/pip install --upgrade pip
.venv/bin/pip install -r requirements.txt
.venv/bin/pip check
.venv/bin/python -m compileall -q app
```

Jika virtual environment sudah ada, tidak perlu membuatnya ulang; cukup pasang
dependency baru setelah `requirements.txt` berubah. `python-multipart` wajib
untuk endpoint upload dan sudah tercantum di manifest.

## Tahap 4 — Siapkan konfigurasi produksi dan rahasia

Buat `.env` hanya jika belum ada:

```bash
cd /srv/developer/mwd
cp .env.example .env
nano .env
```

Jika file sudah ada, edit file itu tanpa menimpanya dengan template. Jangan
menampilkan seluruh isinya menggunakan `cat`, `env`, atau shell tracing.

Variabel backend utama:

| Variabel | Ketentuan |
|---|---|
| `ODOO_HOST` | Host PostgreSQL registry yang dapat dijangkau backend. Host PostgreSQL tenant diatur per baris pada `school_tenants.odoo_db_host`. |
| `DB_PORT` | Port PostgreSQL, biasanya `5432`. |
| `DB_USER` | Role database registry. Kredensial tenant dibaca dari `TENANT_SECRETS_FILE`. |
| `DB_PASSWORD` | Password role registry, disimpan hanya di `.env`. |
| `REGISTRY_DB_NAME` | Nama database registry yang benar dan sudah ada. `DB_NAME` merupakan alias kompatibilitas lama; jangan set keduanya ke nilai yang berbeda. |
| `TENANT_SECRETS_FILE` | Path absolut ke JSON kredensial tenant. Untuk unit user `devmobile`, gunakan `/home/devmobile/.config/mwd/tenant-secrets.json`; file harus dimiliki `devmobile` dengan mode `600`. |
| `JWT_SECRET_KEY` | Secret acak minimal 32 karakter; buat langsung di server. Semua worker/instance harus memakai nilai yang sama dan stabil. Rotasi secret membatalkan access token yang masih aktif. |
| `JWT_ALGORITHM` | Algoritma yang digunakan aplikasi, umumnya `HS256`. |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Masa hidup access token; default 15 menit. |
| `REFRESH_TOKEN_EXPIRE_DAYS` | Masa hidup refresh token; default 30 hari dan diperpanjang saat rotasi. |
| `APP_ENV` | Gunakan `production`. |
| `ODOO_FILESTORE_PATH` | Root filestore bersama, bukan folder tenant tunggal. |

Contoh `.env` untuk `middleware-with-database`:

```env
ODOO_HOST=127.0.0.1
DB_PORT=5432
DB_USER=<user-registry>
DB_PASSWORD=<password-registry>
REGISTRY_DB_NAME=<database-registry>
TENANT_SECRETS_FILE=/home/devmobile/.config/mwd/tenant-secrets.json
```

`DB_USER` dan `DB_PASSWORD` di atas hanya digunakan untuk koneksi registry.
Jangan mengganti nilainya dengan kredensial tenant ketika menambahkan sekolah.
Kredensial tenant disimpan pada file secret dan dipilih melalui
`school_tenants.secret_ref_db`.

Buat file secret sebagai `devmobile`, bukan di `/etc/mwd`. Cara ini mencegah
error `PermissionError: [Errno 13]` saat Uvicorn berjalan sebagai user tersebut:

```bash
install -d -m 700 -o devmobile -g devmobile /home/devmobile/.config/mwd
install -m 600 -o devmobile -g devmobile /dev/null \
  /home/devmobile/.config/mwd/tenant-secrets.json
sudo -u devmobile sh -c 'umask 077; printf "%s\n" \
  "{\"tenant/bogor/postgresql\":{\"username\":\"<user-tenant>\",\"password\":\"<password-tenant>\"}}" \
  > /home/devmobile/.config/mwd/tenant-secrets.json'
chown devmobile:devmobile /home/devmobile/.config/mwd/tenant-secrets.json
chmod 600 /home/devmobile/.config/mwd/tenant-secrets.json
```

Untuk menambahkan tenant baru, gabungkan entry baru ke JSON yang sudah ada;
jangan menimpa entry tenant lain. Setelah `TENANT_SECRETS_FILE` di `.env`
diubah ke path baru, validasi akses dan restart service:

```bash
sudo -u devmobile test -r /home/devmobile/.config/mwd/tenant-secrets.json
stat -c '%U:%G %a %n' /home/devmobile/.config/mwd/tenant-secrets.json
systemctl --user restart mwd-api
journalctl --user -u mwd-api -n 50 --no-pager
```

Jangan menampilkan isi file secret dengan `cat`, memasukkannya ke GitHub
Secrets yang tidak diperlukan, atau menaruh password tenant di registry.

### Secret khusus server testing

Untuk server testing aplikasi, gunakan file terpisah dari produksi langsung di
home directory `/home/devmobile`. Service aktif memakai source
`/srv/developer/mwd`; file `/home/devmobile/mwd-active-backend` bukan direktori
aplikasi dan tidak boleh dipakai sebagai parent path secret:

```bash
test -d "$HOME" &&
test -w "$HOME" ||
  { echo "Home directory tidak dapat ditulis oleh user aktif."; exit 1; }

umask 077
printf "%s\n" \
  "{\"tenant/testing/postgresql\":{\"username\":\"<user-testing>\",\"password\":\"<password-testing>\"}}" \
  > "$HOME/tenant-secrets-testing.json"
chmod 600 "$HOME/tenant-secrets-testing.json"
```

Jalankan perintah tersebut setelah login sebagai `devmobile`; jangan gunakan
`sudo`. Karena file dibuat oleh user aktif, owner dan group otomatis menjadi
`devmobile`. Jika direktori atau file sudah ada tetapi dimiliki `root`, user
`devmobile` tidak dapat memperbaikinya sendiri; minta administrator menjalankan
`chown` satu kali atau gunakan direktori lain yang memang dapat ditulis.

Konfigurasi environment service testing harus menunjuk ke file tersebut:

```env
TENANT_SECRETS_FILE=/home/devmobile/tenant-secrets-testing.json
APP_ENV=testing
```

Entry `tenant/testing/postgresql` hanya contoh. Ganti dengan `secret_ref_db`
dan kredensial database testing yang benar. Pastikan database testing tidak
menggunakan password atau database produksi.

Validasi tanpa mencetak isi secret:

```bash
test -r "$HOME/tenant-secrets-testing.json"
stat -c '%U:%G %a %n' \
  "$HOME/tenant-secrets-testing.json"
```

Buat secret JWT tanpa mencetak nilai secret ke dokumen/chat:

```bash
openssl rand -hex 32
```

Ganti konfigurasi lama `ACCESS_TOKEN_EXPIRE_DAYS` dengan
`ACCESS_TOKEN_EXPIRE_MINUTES` jika masa hidup access token ingin diatur.

Atur izin file:

```bash
chmod 600 /srv/developer/mwd/.env
```

Password database yang pernah terpapar harus dirotasi. Jika role itu juga
digunakan Odoo, koordinasikan perubahan password pada konfigurasi Odoo dan
backend dalam jendela pemeliharaan yang sama. Jangan memasukkan password
langsung sebagai argumen command atau ke shell history.

## Tahap 5 — Verifikasi database dan skema aplikasi

Pastikan registry dan tenant yang diperlukan sudah tersedia. Jangan membuat
database Odoo baru atau mengganti nama database sebagai jalan pintas.

Aplikasi membuat tabel `school_tenants` dan `refresh_tokens` di registry pada
startup jika belum ada. Tabel refresh menyimpan hash token, bukan token mentah.
Database user harus memiliki koneksi, izin schema yang diperlukan untuk
pembuatan tabel, serta izin baca data pada registry dan database tenant.

Flutter menyimpan refresh token di secure storage perangkat dan mencoba rotasi
satu kali saat request middleware menerima HTTP 401. Instalasi lama yang belum
memiliki refresh token perlu login ulang satu kali untuk menerbitkannya.
Refresh token tidak memperbaiki konfigurasi JWT: semua instance backend tetap
wajib berbagi `JWT_SECRET_KEY` yang sama. Jika key berbeda antar-instance,
token access baru pun dapat gagal bergantung pada instance yang menerima
request; selaraskan konfigurasi server secara terpisah dan jangan menaruh key
di aplikasi.

Jalankan backend sementara melalui systemd sesuai Tahap 7, lalu periksa log:

```bash
systemctl --user restart mwd-api
journalctl --user -u mwd-api -n 60 --no-pager
```

Startup sehat berarti tidak ada error autentikasi, `database does not exist`,
izin schema, DNS, atau timeout. Jangan mencetak atau mengirim password saat
mendiagnosis masalah koneksi.

## Tahap 6 — Berikan akses filestore baca-saja

Cari root filestore aktual melalui admin Odoo. Pada server ini path yang pernah
dikonfirmasi:

```text
/opt/odoo16/.local/share/Odoo/filestore
```

Jika `setfacl` belum tersedia, admin dapat memasang ACL tools:

```bash
command -v setfacl || sudo apt-get install -y acl
```

Untuk semua tenant, admin dapat memberi `devmobile` traverse pada parent dan
baca-saja pada filestore:

```bash
sudo setfacl -m u:devmobile:--x /opt/odoo16
sudo setfacl -m u:devmobile:--x /opt/odoo16/.local
sudo setfacl -m u:devmobile:--x /opt/odoo16/.local/share
sudo setfacl -m u:devmobile:--x /opt/odoo16/.local/share/Odoo
sudo setfacl -m u:devmobile:r-x /opt/odoo16/.local/share/Odoo/filestore
sudo setfacl -R -m u:devmobile:r-X /opt/odoo16/.local/share/Odoo/filestore
sudo find /opt/odoo16/.local/share/Odoo/filestore -type d \
  -exec setfacl -m d:u:devmobile:r-x {} +
```

Jika backend hanya memerlukan beberapa tenant, batasi ACL pada direktori tenant
tersebut. Default ACL membantu file baru mewarisi izin yang dibutuhkan; uji
perilaku setelah file baru dibuat. Jangan `chown` seluruh filestore atau
memberi backend izin tulis.

Verifikasi path:

```bash
test -r /opt/odoo16/.local/share/Odoo/filestore \
  && test -x /opt/odoo16/.local/share/Odoo/filestore \
  && echo "filestore root accessible"
sudo -u devmobile find /opt/odoo16/.local/share/Odoo/filestore \
  -type f -print -quit
```

Jika ditemukan file, uji baca pada file yang ditemukan:

```bash
sudo -u devmobile test -r "/path/ke/file-yang-ditemukan" \
  && echo "filestore file readable"
```

## Tahap 7 — Jalankan backend sebagai service

Unit user service:

```text
~/.config/systemd/user/mwd-api.service
```

Contoh unit minimal yang sesuai dengan server ini:

```ini
[Unit]
Description=MWD FastAPI Middleware
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/srv/developer/mwd
EnvironmentFile=/srv/developer/mwd/.env
ExecStart=/srv/developer/mwd/.venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000 --root-path /mobile-api
Restart=on-failure
RestartSec=5
UMask=0077

[Install]
WantedBy=default.target
```

Pada host ini opsi sandbox systemd tambahan pernah menyebabkan
`218/CAPABILITIES`; gunakan konfigurasi minimal dan validasi sebelum
menambahkan hardening khusus. Aktifkan:

```bash
systemctl --user daemon-reload
systemctl --user enable --now mwd-api
systemctl --user status mwd-api --no-pager
```

Admin harus mengaktifkan linger agar user manager berjalan setelah logout dan
boot:

```bash
sudo loginctl enable-linger devmobile
```

Verifikasi:

```bash
loginctl show-user devmobile -p Linger
systemctl --user is-enabled mwd-api
systemctl --user is-active mwd-api
ss -ltn | grep '127.0.0.1:8000'
```

Jika kebijakan server tidak mengizinkan linger, minta admin menyediakan
**system service** yang berjalan sebagai akun `devmobile` dan membaca
`/srv/developer/mwd/.env`. Jangan menjalankan Uvicorn di terminal interaktif
sebagai pengganti service produksi. Jangan gunakan `--reload` di produksi.

Kontrol service dan log:

```bash
systemctl --user status mwd-api
systemctl --user restart mwd-api
systemctl --user stop mwd-api
journalctl --user -u mwd-api -n 100 --no-pager
journalctl --user -u mwd-api -f
```

## Tahap 8 — Pasang reverse proxy Nginx

Admin mengedit server block HTTPS domain yang sudah ada. Buat backup dan
periksa konfigurasi aktif terlebih dahulu:

```bash
readlink -f /etc/nginx/sites-enabled/asetkoptii
sudo cp -a /etc/nginx/sites-available/asetkoptii \
  "/etc/nginx/sites-available/asetkoptii.bak.$(date +%Y%m%d-%H%M%S)"
sudo grep -nE 'server_name|listen 443|location|proxy_pass' \
  /etc/nginx/sites-available/asetkoptii
sudoedit /etc/nginx/sites-available/asetkoptii
```

Di dalam server block HTTPS yang benar, tambahkan location untuk meneruskan
path API ke Uvicorn. Jangan menghapus atau mengubah routing Odoo yang sudah ada;
pastikan tidak ada location yang bentrok.

```nginx
location = /mobile-api {
    return 308 /mobile-api/;
}

location /mobile-api/ {
    client_max_body_size 100m;

    proxy_pass http://127.0.0.1:8000/;
    proxy_http_version 1.1;

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    proxy_read_timeout 120s;
}
```

Slash akhir pada `proxy_pass` menghapus prefix `/mobile-api/` sebelum request
diteruskan. Backend dijalankan dengan `--root-path /mobile-api`. Sesuaikan
batas upload sesuai kebijakan aplikasi dan kapasitas server.

Validasi sebelum reload:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

Jangan reload jika tes gagal. Perubahan Nginx/sertifikat memerlukan hak admin.

## Tahap 9 — Uji kesiapan backend

Uji lokal sebagai `devmobile`:

```bash
systemctl --user is-active mwd-api
curl -i --max-time 10 http://127.0.0.1:8000/
curl -i --max-time 10 http://127.0.0.1:8000/openapi.json
```

Uji melalui Nginx:

```bash
curl -i --max-time 10 \
  https://kp-sekolah.asetkoptii.com/mobile-api/
curl -i --max-time 10 \
  https://kp-sekolah.asetkoptii.com/mobile-api/openapi.json
curl -i --max-time 10 \
  https://kp-sekolah.asetkoptii.com/mobile-api/api/v1/auth/schools
```

Backend dinyatakan siap ketika:

1. Unit service `active` dan tetap hidup setelah koneksi SSH ditutup.
2. Listener Uvicorn hanya `127.0.0.1:8000`, tidak `0.0.0.0:8000`.
3. Root/OpenAPI lokal merespons sesuai aplikasi.
4. Permintaan melalui HTTPS diproses FastAPI, bukan halaman Odoo.
5. Endpoint sekolah merespons sesuai kontrak API.
6. Koneksi registry dan tenant berfungsi, serta operasi yang memerlukan
   filestore dapat membaca file.
7. Setelah reboot terjadwal atau uji pemulihan yang disetujui admin, service
   otomatis hidup kembali.

## Tahap 10 — Operasi, pemantauan, dan pemulihan

Pemeriksaan rutin:

```bash
systemctl --user is-active mwd-api
systemctl --user status mwd-api --no-pager
journalctl --user -u mwd-api --since today --no-pager
df -h /
free -h
pg_isready -h 127.0.0.1 -p 5432
```

Untuk `502 Bad Gateway`, periksa service dan kedua sisi koneksi:

```bash
systemctl --user status mwd-api --no-pager
ss -ltn | grep '127.0.0.1:8000'
journalctl --user -u mwd-api -n 100 --no-pager
sudo tail -n 100 /var/log/nginx/error.log
```

Jika service gagal atau request menghasilkan error, cari pesan error spesifik;
contoh:

- `218/CAPABILITIES`: opsi sandbox unit tidak didukung; tinjau unit minimal.
- `python-multipart` tidak tersedia: pasang dependensi dari manifest pada
  virtual environment yang benar.
- `asyncpg.exceptions.InvalidCatalogNameError: database "..." does not exist`:
  bedakan database registry (`REGISTRY_DB_NAME` di `.env`) dari database tenant.
  Jika error muncul saat request tenant, periksa kombinasi
  `odoo_db_host`, `odoo_db_port`, dan `odoo_db`; ketiganya harus menunjuk ke
  katalog PostgreSQL yang benar. Gunakan `odoo_url` hanya sebagai URL HTTP Odoo,
  bukan sebagai host PostgreSQL.

  Periksa baris tenant tanpa menampilkan kredensial:

  ```bash
  psql -h 127.0.0.1 -U ROLE_BACKEND -d DB_REGISTRY
  ```

  Ganti `ROLE_BACKEND` dan `DB_REGISTRY` dengan nama role serta registry yang
  benar, lalu jalankan:

  ```sql
  SELECT id, school_name, odoo_url, odoo_db_host, odoo_db_port, odoo_db, is_active
  FROM school_tenants
  WHERE school_code = 'bogor';
  ```

  Minta admin memastikan nama database tenant yang sebenarnya (misalnya dengan
  `\l` di `psql` dan mencocokkannya dengan konfigurasi Odoo). Setelah dikonfirmasi,
  perbaiki hanya host/port/nama database pada baris tenant yang tepat, bukan
  `REGISTRY_DB_NAME` atau `odoo_url`. Uji koneksi dari server middleware:

  ```bash
  psql -h <odoo_db_host> -p <odoo_db_port> -U "$DB_USER" -d <odoo_db> \
    -c "SELECT current_database(), current_user;"
  ```
- autentikasi ditolak: koordinasikan rotasi password database pada semua
  konsumen role terkait.
- `Permission denied` pada filestore: admin meninjau ACL dan parent-directory
  traversal tanpa memberi izin tulis.

Sebelum update source, perubahan konfigurasi, rotasi kredensial, atau reboot:

1. Informasikan maintenance window kepada pemilik layanan.
2. Pastikan backup dan cara rollback tersedia dan sudah dipahami admin.
3. Hindari menyalin `.env` ke backup yang dapat dibaca publik.
4. Sesudah perubahan, ulangi uji lokal dan publik pada Tahap 9.

## Kriteria penutupan deployment

- [ ] Prasyarat server, kapasitas, DNS, HTTPS, dan batas jaringan telah diperiksa.
- [ ] Source dan dependency tervalidasi.
- [ ] `.env` produksi memiliki permission `600` dan rahasia telah dirotasi.
- [ ] Registry dan database tenant yang diperlukan dapat diakses.
- [ ] ACL filestore baca-saja sesuai scope tenant.
- [ ] Service berjalan di loopback dan persisten setelah logout/boot.
- [ ] Nginx lolos `nginx -t` dan meneruskan request ke backend.
- [ ] Tes API lokal dan publik berhasil.
- [ ] Admin memiliki prosedur monitoring, backup, rollback, dan recovery.
