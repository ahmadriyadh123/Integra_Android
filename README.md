# Integra Mobile App

Aplikasi sekolah yang terdiri dari aplikasi mobile Flutter dan middleware REST API berbasis FastAPI untuk menghubungkan perangkat mobile dengan Odoo melalui RPC.

## Struktur Project

```text
.
├── fast-api-middleware/   # Backend FastAPI dan integrasi Odoo RPC
├── flutter-mobile/        # Aplikasi Flutter Android/Web
└── README.md
```

## Prasyarat

- Flutter SDK dengan Dart SDK sesuai `flutter-mobile/pubspec.yaml`
- Python 3.13 atau versi yang kompatibel
- Odoo yang dapat diakses oleh backend
- Android SDK untuk build Android
- Docker, jika backend dijalankan sebagai container

## Menjalankan Backend

Masuk ke folder backend:

```powershell
cd fast-api-middleware
```

Buat environment Python dan install dependency:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Salin konfigurasi contoh dan isi nilai Odoo serta JWT:

```powershell
Copy-Item .env.example .env
```

Contoh nilai penting di `.env`:

```env
APP_ENV=development
ODOO_HOST=localhost
ODOO_DB=nama_database_odoo
ODOO_SCHEME=http
ODOO_PORT=8069
ODOO_ADMIN_USER=admin
ODOO_ADMIN_PASS=password_odoo
JWT_SECRET_KEY=ganti-dengan-secret-yang-aman
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_DAYS=30
CORS_ALLOW_ORIGINS=
```

Jalankan server development:

```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Endpoint pemeriksaan:

- `GET http://localhost:8000/`
- `GET http://localhost:8000/health/live`
- `GET http://localhost:8000/health/ready`
- Dokumentasi API: `http://localhost:8000/docs`

Untuk deployment production, lihat [fast-api-middleware/DEPLOYMENT.md](fast-api-middleware/DEPLOYMENT.md).

## Menjalankan Flutter

Masuk ke folder aplikasi:

```powershell
cd flutter-mobile
flutter pub get
```

Jalankan dengan alamat backend lokal:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Untuk perangkat fisik, gunakan alamat IP komputer pada jaringan lokal, misalnya:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.7:8000/api/v1
```

Alamat API juga dapat diisi langsung pada form login. Alamat yang disimpan akan tersimpan lokal dan tersedia kembali melalui dropdown pada login.

Catatan:

- Emulator Android menggunakan `10.0.2.2` untuk mengakses `localhost` komputer host.
- Perangkat fisik dan komputer backend harus berada pada jaringan yang sama.
- Gunakan HTTPS dan domain production untuk release.

## Test dan Analisis

Dari folder `flutter-mobile`:

```powershell
flutter analyze
flutter test
```

## Build Release Android

Membuat APK release:

```powershell
cd flutter-mobile
flutter clean
flutter pub get
flutter build apk --release
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Membuat Android App Bundle untuk Google Play:

```powershell
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.com/api/v1
```

Output:

```text
build/app/outputs/bundle/release/app-release.aab
```

Jika alamat API akan dipilih melalui form login, `--dart-define` dapat dihilangkan. Untuk build production, pastikan konfigurasi signing Android sudah tersedia.

## Docker Backend

Dari folder `fast-api-middleware`:

```powershell
docker build --tag sekolah-middleware:production .
docker run --detach `
  --name sekolah-middleware `
  --restart unless-stopped `
  --publish 127.0.0.1:8000:8000 `
  --env-file .env `
  sekolah-middleware:production
```

Jangan mengekspos port `8000` langsung ke internet pada production. Gunakan reverse proxy HTTPS dan batasi secret production melalui secret manager.

## Keamanan

- Jangan commit `.env`, password Odoo, JWT secret, keystore, atau credential lainnya.
- Gunakan `JWT_SECRET_KEY` minimal 32 karakter pada production.
- Gunakan HTTPS untuk API production.
- Batasi CORS hanya ke origin yang diperlukan.
- Gunakan `uvicorn` tanpa `--reload` pada production.
