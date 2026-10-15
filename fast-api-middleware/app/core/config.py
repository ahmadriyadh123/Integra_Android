import base64
import logging
import os

from pydantic_settings import BaseSettings, SettingsConfigDict

logger = logging.getLogger(__name__)


class Settings(BaseSettings):
    PROJECT_NAME: str = "FastAPI Middleware Odoo RPC"
    APP_ENV: str = "development"
    CORS_ALLOW_ORIGINS: str = ""
    REGISTRY_DB_HOST: str = "127.0.0.1"
    REGISTRY_DB_PORT: int = 5432
    REGISTRY_DB_NAME: str
    REGISTRY_DB_USER: str
    REGISTRY_DB_PASSWORD: str
    ODOO_FILESTORE_PATH: str = ""

    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_DAYS: int = 30

    @property
    def cors_origins(self) -> list[str]:
        return [
            origin.strip()
            for origin in self.CORS_ALLOW_ORIGINS.split(",")
            if origin.strip()
        ]

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )


settings = Settings()

if settings.APP_ENV.lower() == "production":
    if len(settings.JWT_SECRET_KEY) < 32:
        raise ValueError("JWT_SECRET_KEY production harus minimal 32 karakter")


def get_attachment_base64(store_fname: str, odoo_db: str) -> str | None:
    """Membaca file gambar dari Odoo Filestore berdasarkan nama DB Tenant"""
    if not store_fname or not odoo_db or not settings.ODOO_FILESTORE_PATH:
        return None
    try:
        clean_store_fname = os.path.normpath(store_fname)
        base_filestore = os.path.normpath(settings.ODOO_FILESTORE_PATH)

        file_path = os.path.join(base_filestore, odoo_db, clean_store_fname)

        if os.path.exists(file_path) and os.path.isfile(file_path):
            with open(file_path, "rb") as image_file:
                encoded_string = base64.b64encode(image_file.read()).decode("utf-8")
                return f"data:image/png;base64,{encoded_string}"
    except Exception as exc:
        logger.error(f"[config] Gagal membaca file fisik: {exc}")

    return None
