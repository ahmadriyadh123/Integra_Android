import xmlrpc.client
from urllib.parse import urlsplit
from typing import List, Dict, Any
from app.core.models import SchoolTenant

ODOO_RPC_TIMEOUT_SECONDS = 8


class _TimeoutTransport(xmlrpc.client.Transport):
    def make_connection(self, host: str):
        connection = super().make_connection(host)
        connection.timeout = ODOO_RPC_TIMEOUT_SECONDS
        return connection


class _TimeoutSafeTransport(xmlrpc.client.SafeTransport):
    def make_connection(self, host: str):
        connection = super().make_connection(host)
        connection.timeout = ODOO_RPC_TIMEOUT_SECONDS
        return connection


class OdooAccessError(PermissionError):
    pass


class OdooRPCClient:
    def __init__(self, url: str, db: str):
        if not url.strip() or not db.strip():
            raise ValueError("URL dan nama database Odoo tenant wajib diisi.")
        self.url = url.rstrip("/")
        self.db = db
        transport = (
            _TimeoutSafeTransport()
            if urlsplit(self.url).scheme == "https"
            else _TimeoutTransport()
        )
        self.common = xmlrpc.client.ServerProxy(
            f"{self.url}/xmlrpc/2/common", transport=transport
        )
        object_transport = (
            _TimeoutSafeTransport()
            if urlsplit(self.url).scheme == "https"
            else _TimeoutTransport()
        )
        self.models = xmlrpc.client.ServerProxy(
            f"{self.url}/xmlrpc/2/object", transport=object_transport
        )

    @classmethod
    def get_client(cls, tenant: SchoolTenant) -> "OdooRPCClient":
        """Factory method untuk instansiasi OdooRPCClient berdasarkan data Tenant"""
        return cls(
            url=tenant.odoo_url,
            db=tenant.odoo_db
        )

    def execute_kw(
        self, 
        uid: int, 
        password: str, 
        model: str, 
        method: str, 
        args: list, 
        kwargs: dict = None,
    ):
        if kwargs is None:
            kwargs = {}
        try:
            return self.models.execute_kw(
                self.db, uid, password, model, method, args, kwargs
            )
        except xmlrpc.client.Fault as exc:
            if exc.faultCode == 4:
                raise OdooAccessError(
                    f"Odoo menolak akses ke {model}.{method}; periksa hak akses "
                    "pengguna yang sedang login."
                ) from exc
            raise

    def search_read(
        self, 
        uid: int, 
        password: str, 
        model: str, 
        domain: list = None, 
        fields: list = None, 
        limit: int = 80, 
        order: str = None,
    ) -> List[Dict[str, Any]]:
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
        )

    def write(
        self, 
        uid: int, 
        password: str, 
        model: str, 
        ids: list, 
        values: dict,
    ) -> bool:
        return self.execute_kw(
            uid=uid, password=password, model=model, method='write', args=[ids, values]
        )

    def create(
        self, 
        uid: int, 
        password: str, 
        model: str, 
        values: dict,
    ) -> int:
        return self.execute_kw(
            uid=uid, password=password, model=model, method='create', args=[values]
        )