import xmlrpc.client
from typing import List, Dict, Any
from app.core.config import settings

class OdooRPCClient:
    def __init__(self, session_or_token: str = None):
        self.url = settings.ODOO_URL
        self.db = settings.ODOO_DB
        self.common = xmlrpc.client.ServerProxy(f"{self.url}/xmlrpc/2/common")
        self.models = xmlrpc.client.ServerProxy(f"{self.url}/xmlrpc/2/object")

    def execute_kw(
        self, 
        uid: int, 
        password: str, 
        model: str, 
        method: str, 
        args: list, 
        kwargs: dict = None,
        use_sudo: bool = False
    ):
        """
        Meneruskan panggilan ke Odoo ORM.
        Jika use_sudo=True, gunakan kredensial ODOO_ADMIN untuk bypass ACL & Record Rules Odoo.
        """
        if kwargs is None:
            kwargs = {}

        exec_uid = uid
        exec_pass = password
        if use_sudo and settings.ODOO_ADMIN_USER and settings.ODOO_ADMIN_PASS:
            try:
                admin_uid = self.common.authenticate(
                    self.db, settings.ODOO_ADMIN_USER, settings.ODOO_ADMIN_PASS, {}
                )
                if admin_uid:
                    exec_uid = admin_uid
                    exec_pass = settings.ODOO_ADMIN_PASS
            except Exception:
                pass

        return self.models.execute_kw(
            self.db, exec_uid, exec_pass, model, method, args, kwargs
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
        """Query search_read."""
        kwargs = {
            'fields': fields or [],
            'limit': limit
        }
        if order:
            kwargs['order'] = order

        return self.execute_kw(
            uid=uid,
            password=password,
            model=model,
            method='search_read',
            args=[domain or []],
            kwargs=kwargs,
            use_sudo=use_sudo
        )

    def write(
        self, 
        uid: int, 
        password: str, 
        model: str, 
        ids: list, 
        values: dict,
        use_sudo: bool = False
    ) -> bool:
        return self.execute_kw(
            uid=uid, password=password, model=model, method='write', args=[ids, values], use_sudo=use_sudo
        )

    def create(
        self,
        uid: int,
        password: str,
        model: str,
        values: dict,
        use_sudo: bool = False
    ) -> int:
        return self.execute_kw(
            uid=uid, password=password, model=model, method='create', args=[values], use_sudo=use_sudo
        )