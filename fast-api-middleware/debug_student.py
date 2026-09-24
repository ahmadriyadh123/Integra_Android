"""
Script debug: cek apakah filter student_id.user_id bisa dipakai.
Jalankan: python debug_student.py <username> <password>
"""
import sys
import os
import xmlrpc.client
from dotenv import load_dotenv

load_dotenv()
ODOO_URL = f"http://{os.environ['ODOO_HOST']}:8069"
ODOO_DB  = "kp-sekolah.asetkoptii.com"

def main():
    if len(sys.argv) < 3:
        print("Usage: python debug_student.py <username> <password>")
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

    # Cek field apa saja yang ada di op.student (khususnya user_id / user)
    print("\n=== field op.student yang berhubungan dengan res.users ===")
    try:
        fields = models.execute_kw(
            ODOO_DB, uid, password, 'op.student', 'fields_get', [],
            {'attributes': ['string', 'type', 'relation']}
        )
        for k, v in fields.items():
            if v.get('relation') in ('res.users', 'res.partner') or 'user' in k.lower():
                print(f"  {k}: type={v['type']} relation={v.get('relation','')}")
    except Exception as e:
        print(f"  ERROR fields_get op.student: {e}")

    # Test filter dot-notation student_id.user_id
    print(f"\n=== test filter ('student_id.user_id', '=', {uid}) ===")
    try:
        recs = models.execute_kw(
            ODOO_DB, uid, password, 'op.attendance.line', 'search_read',
            [[('student_id.user_id', '=', uid)]],
            {'fields': ['id', 'student_id', 'attendance_date'], 'limit': 5}
        )
        print(f"  Berhasil! Jumlah record: {len(recs)}")
        for r in recs:
            print(f"    {r}")
    except Exception as e:
        print(f"  ERROR: {e}")

if __name__ == '__main__':
    main()
