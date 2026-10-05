import xmlrpc.client
from typing import List, Dict, Any
from app.core.config import settings
from app.core.models import SchoolTenant


class OdooAccessError(PermissionError):
    pass


class OdooServiceAccountError(RuntimeError):
    pass


class OdooRPCClient:
    def __init__(self, url: str = None, db: str = None):
        # Jika url/db tidak dioper, gunakan fallback dari config
        self.url = (url or settings.ODOO_URL).rstrip("/")
        self.db = db or settings.ODOO_DB
        
        self.common = xmlrpc.client.ServerProxy(f"{self.url}/xmlrpc/2/common")
        self.models = xmlrpc.client.ServerProxy(f"{self.url}/xmlrpc/2/object")

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
        use_sudo: bool = False
    ):
        if kwargs is None:
            kwargs = {}
        exec_uid = uid
        exec_pass = password

        if use_sudo:
            if not settings.ODOO_ADMIN_USER or not settings.ODOO_ADMIN_PASS:
                raise OdooServiceAccountError(
                    "Operasi Odoo ini memerlukan ODOO_ADMIN_USER dan "
                    "ODOO_ADMIN_PASS yang valid."
                )
            try:
                admin_uid = self.common.authenticate(
                    self.db, settings.ODOO_ADMIN_USER, settings.ODOO_ADMIN_PASS, {}
                )
            except Exception as exc:
                raise OdooServiceAccountError(
                    "Autentikasi akun layanan Odoo gagal untuk operasi elevated."
                ) from exc
            if not admin_uid:
                raise OdooServiceAccountError(
                    "Autentikasi akun layanan Odoo ditolak untuk operasi elevated."
                )
            exec_uid = admin_uid
            exec_pass = settings.ODOO_ADMIN_PASS

        try:
            return self.models.execute_kw(
                self.db, exec_uid, exec_pass, model, method, args, kwargs
            )
        except xmlrpc.client.Fault as exc:
            if exc.faultCode == 4:
                raise OdooAccessError(
                    f"Odoo menolak akses ke {model}.{method}; periksa hak akses "
                    "akun layanan Odoo."
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
        use_sudo: bool = False
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