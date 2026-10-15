import json
from pathlib import Path
from typing import TypedDict

from app.core.config import settings


class TenantCredentials(TypedDict):
    username: str
    password: str


class TenantSecretError(RuntimeError):
    """Raised when a tenant database secret cannot be resolved."""


def get_tenant_credentials(secret_ref: str | None) -> TenantCredentials:
    if not secret_ref:
        raise TenantSecretError("Tenant belum memiliki referensi secret database.")

    secret_file = Path(settings.TENANT_SECRETS_FILE)
    if not settings.TENANT_SECRETS_FILE or not secret_file.is_file():
        raise TenantSecretError("Penyimpanan secret tenant belum dikonfigurasi.")

    try:
        secrets = json.loads(secret_file.read_text(encoding="utf-8"))
        credentials = secrets[secret_ref]
        username = credentials["username"]
        password = credentials["password"]
    except (OSError, json.JSONDecodeError, KeyError, TypeError) as exc:
        raise TenantSecretError(
            "Secret database tenant tidak dapat dibaca."
        ) from exc

    if not isinstance(username, str) or not username:
        raise TenantSecretError("Username secret tenant tidak valid.")
    if not isinstance(password, str) or not password:
        raise TenantSecretError("Password secret tenant tidak valid.")
    return {"username": username, "password": password}
