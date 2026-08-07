"""
Script debug untuk cek akses kaldik.sd dan course_id siswa.
Jalankan: python debug_kaldik.py <username> <password>
"""
import sys
import xmlrpc.client

ODOO_URL = "http://203.145.34.16:8069"
ODOO_DB  = "kp-sekolah.asetkoptii.com"

def main():
    if len(sys.argv) < 3:
        print("Usage: python debug_kaldik.py <username> <password>")
        sys.exit(1)

    username = sys.argv[1]
    password = sys.argv[2]

    common = xmlrpc.client.ServerProxy(f"{ODOO_URL}/xmlrpc/2/common")
    models = xmlrpc.client.ServerProxy(f"{ODOO_URL}/xmlrpc/2/object")

    uid = common.authenticate(ODOO_DB, username, password, {})
    if not uid:
        print("LOGIN GAGAL")
        sys.exit(1)
    print(f"Login OK -> uid={uid}")

    # 1. Cek akses kaldik.sd tanpa filter
    print("\n=== query kaldik.sd domain=[] ===")
    try:
        recs = models.execute_kw(
            ODOO_DB, uid, password, 'kaldik.sd', 'search_read',
            [[]],
            {'fields': ['id', 'kelas_id', 'semester_id'], 'limit': 5}
        )
        print(f"  Berhasil, {len(recs)} record: {recs}")
    except Exception as e:
        print(f"  ERROR: {e}")

    # 2. Cek field course_id / batch_id di op.attendance.line milik user ini
    # (kita sudah tahu user bisa akses attendance dengan record rule)
    print("\n=== course_id dari op.attendance.line milik user ini ===")
    try:
        recs = models.execute_kw(
            ODOO_DB, uid, password, 'op.attendance.line', 'search_read',
            [[]],
            {'fields': ['id', 'student_id', 'course_id', 'batch_id'], 'limit': 3}
        )
        print(f"  Hasil: {recs}")
    except Exception as e:
        print(f"  ERROR: {e}")

    # 3. Cek field di op.student yang ada course/batch
    print("\n=== field op.student terkait course/batch (via fields_get) ===")
    try:
        fields = models.execute_kw(
            ODOO_DB, uid, password, 'op.student', 'fields_get', [],
            {'attributes': ['string', 'type', 'relation']}
        )
        for k, v in fields.items():
            if any(kw in k.lower() for kw in ['course', 'batch', 'class', 'kelas']):
                print(f"  {k}: type={v['type']} relation={v.get('relation','')}")
    except Exception as e:
        print(f"  ERROR op.student fields_get: {e}")

if __name__ == '__main__':
    main()
