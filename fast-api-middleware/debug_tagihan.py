"""
Script debug untuk cek akses account.move (tagihan) untuk user portal.
Jalankan: python debug_tagihan.py <username> <password>
"""
import sys
import xmlrpc.client

ODOO_URL = "http://203.145.34.16:8069"
ODOO_DB  = "kp-sekolah.asetkoptii.com"

def main():
    if len(sys.argv) < 3:
        print("Usage: python debug_tagihan.py <username> <password>")
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

    # 1. Cek partner_id user ini
    print("\n=== partner_id user ===")
    try:
        rec = models.execute_kw(
            ODOO_DB, uid, password, 'res.users', 'search_read',
            [[('id', '=', uid)]],
            {'fields': ['id', 'name', 'partner_id'], 'limit': 1}
        )
        print(f"  {rec}")
        partner_id = rec[0]['partner_id'][0] if rec else None
        print(f"  partner_id = {partner_id}")
    except Exception as e:
        print(f"  ERROR: {e}")
        partner_id = None

    # 2. Cek akses account.move tanpa filter
    print("\n=== query account.move domain=[] (maks 3) ===")
    try:
        recs = models.execute_kw(
            ODOO_DB, uid, password, 'account.move', 'search_read',
            [[]],
            {'fields': ['id', 'name', 'move_type', 'state', 'payment_state',
                        'partner_id', 'amount_total', 'amount_residual',
                        'invoice_date', 'invoice_date_due'], 'limit': 3}
        )
        print(f"  Berhasil, {len(recs)} record:")
        for r in recs:
            print(f"    {r}")
    except Exception as e:
        print(f"  ERROR: {e}")

    # 3. Cek dengan filter out_invoice + posted
    print("\n=== query account.move out_invoice+posted ===")
    try:
        recs = models.execute_kw(
            ODOO_DB, uid, password, 'account.move', 'search_read',
            [[('move_type', '=', 'out_invoice'), ('state', '=', 'posted')]],
            {'fields': ['id', 'name', 'payment_state', 'partner_id',
                        'amount_total', 'amount_residual'], 'limit': 5}
        )
        print(f"  Berhasil, {len(recs)} record:")
        for r in recs:
            print(f"    {r}")
    except Exception as e:
        print(f"  ERROR: {e}")

if __name__ == '__main__':
    main()
