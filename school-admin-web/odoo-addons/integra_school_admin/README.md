# Integra School Admin Odoo Addon

Addon native Odoo untuk menampilkan representasi direktori sekolah dan
memeriksa koneksi ke server Odoo tenant.

## Sumber data registry

Untuk project Integra ini, **database registry middleware adalah source of
truth**. Backend mobile membaca tabel PostgreSQL `school_tenants` melalui
endpoint:

```text
GET /api/v1/auth/schools
```

Kontrak registry:

| Registry `school_tenants` | Model addon `school.tenant` |
| --- | --- |
| `school_code` | `school_code` |
| `school_name` | `school_name` |
| `odoo_url` | `odoo_url` |
| `odoo_db` | `odoo_db` |
| `is_active` | `active` |

Model addon berada pada database Odoo dan **bukan** tabel
`middleware_registry.school_tenants`. Addon tidak mengubah, membaca langsung,
atau menyinkronkan otomatis tabel registry. Karena itu, perubahan data yang
harus terlihat oleh aplikasi mobile tetap harus dilakukan pada database
registry middleware.

Versi ini menyediakan sinkronisasi eksplisit melalui endpoint admin backend
`PUT /api/v1/admin/tenants/{school_code}`. Tombol **Sinkronkan registry**
tersedia pada form dan daftar sekolah.
Konfigurasikan parameter sistem Odoo berikut sebagai administrator:

```text
integra_school_admin.registry_api_url
integra_school_admin.registry_admin_token
```

Token harus sama dengan `REGISTRY_ADMIN_TOKEN` pada backend dan tidak boleh
disimpan di Git. Password database tenant tidak pernah dikirim; hanya
`secret_ref_db` yang dikirim sebagai referensi ke file secret backend.

Field `active` pada addon hanya merupakan pemetaan lokal dari
`school_tenants.is_active`. Nama `active` dipertahankan agar kompatibel dengan
mekanisme arsip standar Odoo.

## Instalasi

1. Salin folder `integra_school_admin` ke direktori custom `addons_path` Odoo.
2. Mulai ulang Odoo dan perbarui daftar Apps.
3. Instal atau upgrade **Integra School Admin**.
4. Pastikan pengguna pengelola termasuk grup **Administration/Settings**
   (`base.group_system`).

Panduan lengkap untuk instalasi pada Odoo pusat tersedia pada
[PANDUAN-ODOO-PUSAT.md](./PANDUAN-ODOO-PUSAT.md).

Menu yang tersedia:

```text
School Admin → Daftar sekolah
```

Versi `1.2.0` tidak lagi memuat menu **Konfigurasi Model**. Upgrade addon
akan menghapus menu lama tersebut dari database Odoo.

## Validasi dan koneksi

- `school_code` dan `odoo_db` harus unik, mengikuti constraint registry.
- Kode sekolah dinormalisasi menjadi huruf besar.
- `odoo_url` harus berupa URL HTTP/HTTPS tanpa kredensial, query, atau fragment.
- **Periksa koneksi Odoo** hanya memvalidasi respons endpoint XML-RPC
  `/xmlrpc/2/common`; fitur ini tidak mengubah registry middleware.
- Untuk tenant non-localhost, koneksi akun administrator harus menggunakan
  HTTPS.

Jalankan tes addon menggunakan Odoo pada database uji:

```powershell
odoo-bin --addons-path=<addons_path> -d <database> `
  -i integra_school_admin --test-enable --stop-after-init
```

Fixture npm pada
`../../test/fixtures/odoo-tenant-directory.json` hanya untuk menguji format
direktori; fixture tersebut tidak digunakan oleh Odoo dan tidak berisi
kredensial.
