import xmlrpc.client
from typing import Dict, Any, Optional
from app.core.config import settings
from app.core.odoo_client import OdooRPCClient

class AuthRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def authenticate_odoo_user(self, username: str, password: str) -> Optional[Dict[str, Any]]:
        """
        Memverifikasi username dan password langsung ke mesin Odoo Authentication.
        Jika berhasil, Odoo akan mengembalikan Integer User ID (uid).
        """
        try:
            common = xmlrpc.client.ServerProxy(f"{self.odoo.url}/xmlrpc/2/common")
            
            # Melakukan authentikasi ke database Odoo
            uid = common.authenticate(
                self.odoo.db, 
                username, 
                password, 
                {}
            )
            
            if not uid:
                return None  # Kredensial salah
                
            # Mengambil profil dasar res.users & res.partner pengguna yang login
            user_records = self.odoo.search_read(
                uid=uid,
                password=password,
                model='res.users',
                domain=[('id', '=', uid)],
                fields=['id', 'name', 'login', 'email', 'partner_id'],
                limit=1
            )
            
            if not user_records:
                return None
                
            user_data = user_records[0]
            partner_val = user_data.get('partner_id')
            partner_id = partner_val[0] if isinstance(partner_val, list) and partner_val else None

            return {
                "uid": uid,
                "name": str(user_data.get('name') or ''),
                "username": str(user_data.get('login') or username),
                "email": str(user_data.get('email') or ''),
                "partner_id": partner_id
            }
        except Exception:
            return None