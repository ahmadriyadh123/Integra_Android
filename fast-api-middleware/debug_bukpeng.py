"""
Script debug untuk cek akses bukpeng.sd dan bukpeng.sd.line untuk user portal.
Jalankan: python debug_bukpeng.py <username> <password>
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
        print("Usage: python debug_bukpeng.py <username> <password>")
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

    # 1. bukpeng.sd (header)
    print("\n=== bukpeng.sd domain=[] ===")
    try:
        recs = models.execute_kw(
            ODOO_DB, uid, password, 'bukpeng.sd', 'search_read',
            [[]],
            {'fields': ['id', 'student_id', 'kelas_id', 'tahun_id', 'status'], 'limit': 3}
        )
        print(f"  Berhasil, {len(recs)} record:")
        for r in recs:
            print(f"    {r}")
    except Exception as e:
        print(f"  ERROR: {e}")

    # 2. bukpeng.sd.line (detail mingguan)
    print("\n=== bukpeng.sd.line domain=[] ===")
    try:
        recs = models.execute_kw(
            ODOO_DB, uid, password, 'bukpeng.sd.line', 'search_read',
            [[]],
            {'fields': ['id', 'bukpeng_sd_id', 'pekan_ke', 'bulan', 'senin'], 'limit': 5}
        )
        print(f"  Berhasil, {len(recs)} record:")
        for r in recs:
            print(f"    {r}")
    except Exception as e:
        print(f"  ERROR: {e}")

if __name__ == '__main__':
    main()
