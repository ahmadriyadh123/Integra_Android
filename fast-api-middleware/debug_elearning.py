"""
Script debug untuk cek akses slide.channel dan slide.slide untuk user portal.
Jalankan: python debug_elearning.py <username> <password>
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
        print("Usage: python debug_elearning.py <username> <password>")
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

    # 1. Cek slide.channel
    print("\n=== slide.channel (maks 3) ===")
    try:
        recs = models.execute_kw(
            ODOO_DB, uid, password, 'slide.channel', 'search_read',
            [[('is_published', '=', True)]],
            {'fields': ['id', 'name', 'user_id', 'total_slides', 'is_published', 'description'], 'limit': 3}
        )
        print(f"  Berhasil, {len(recs)} record:")
        for r in recs:
            print(f"    {r}")
    except Exception as e:
        print(f"  ERROR: {e}")

    # 2. Cek slide.slide
    print("\n=== slide.slide (maks 5) ===")
    try:
        recs = models.execute_kw(
            ODOO_DB, uid, password, 'slide.slide', 'search_read',
            [[('is_published', '=', True)]],
            {'fields': ['id', 'name', 'channel_id', 'slide_category', 'slide_type',
                        'url', 'sequence', 'is_published'], 'limit': 5}
        )
        print(f"  Berhasil, {len(recs)} record:")
        for r in recs:
            print(f"    {r}")
    except Exception as e:
        print(f"  ERROR: {e}")

if __name__ == '__main__':
    main()
