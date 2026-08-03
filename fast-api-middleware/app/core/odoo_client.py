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
        order: str = None
    ) -> List[Dict[str, Any]]:
        kwargs = {
            'fields': fields or [],
            'limit': limit
        }
        if order:
            kwargs['order'] = order

        return self.models.execute_kw(
            self.db, uid, password, model, 'search_read', [domain or []], kwargs
        )

    def write(self, uid: int, password: str, model: str, ids: list, values: dict) -> bool:
        return self.models.execute_kw(
            self.db, uid, password, model, 'write', [ids, values]
        )