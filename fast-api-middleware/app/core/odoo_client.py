import xmlrpc.client
from typing import List, Dict, Any
from app.core.config import settings

class OdooRPCClient:
    def __init__(self, session_or_token: str = None):
        self.url = settings.ODOO_URL
        self.db = settings.ODOO_DB
        self.common = xmlrpc.client.ServerProxy(f"{self.url}/xmlrpc/2/common")
        self.models = xmlrpc.client.ServerProxy(f"{self.url}/xmlrpc/2/object")

    def execute_kw(self, uid: int, password: str, model: str, method: str, args: list, kwargs: dict = None):
        """
        Meneruskan panggilan ke Odoo ORM.
        Odoo akan mengevaluasi ACL & Record Rule secara otomatis untuk 'uid' tersebut!
        """
        if kwargs is None:
            kwargs = {}
        return self.models.execute_kw(
            self.db, uid, password, model, method, args, kwargs
        )

    def search_read(
        self, 
        uid: int, 
        password: str, 
        model: str, 
        domain: list = None, 
        fields: list = None, 
        limit: int = 80, 
        order: str = None,
        use_sudo: bool = False
    ) -> List[Dict[str, Any]]:
        """
        Query search_read. Jika use_sudo=True, gunakan admin credentials
        untuk bypass ACL (setara sudo() di Odoo internal API).
        """
        kwargs = {
            'fields': fields or [],
            'limit': limit
        }
        if order:
            kwargs['order'] = order

        # Gunakan admin credentials jika use_sudo=True
        if use_sudo and settings.ODOO_ADMIN_USER and settings.ODOO_ADMIN_PASS:
            admin_uid = self.common.authenticate(
                self.db, settings.ODOO_ADMIN_USER, settings.ODOO_ADMIN_PASS, {}
            )
            if admin_uid:
                return self.models.execute_kw(
                    self.db, admin_uid, settings.ODOO_ADMIN_PASS,
                    model, 'search_read', [domain or []], kwargs
                )

        # Fallback ke user credentials biasa
        return self.models.execute_kw(
            self.db, uid, password, model, 'search_read', [domain or []], kwargs
        )

    def write(self, uid: int, password: str, model: str, ids: list, values: dict) -> bool:
        return self.models.execute_kw(
            self.db, uid, password, model, 'write', [ids, values]
        )