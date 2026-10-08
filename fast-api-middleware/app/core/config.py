import os
import base64
import logging
from pydantic_settings import BaseSettings, SettingsConfigDict

logger = logging.getLogger(__name__)

class Settings(BaseSettings):
    PROJECT_NAME: str = "FastAPI Middleware Odoo RPC"
    APP_ENV: str = "development"
    CORS_ALLOW_ORIGINS: str = ""

    # Database PostgreSQL khusus Middleware (Tenant Registry)
    DATABASE_URL: str = "postgresql://user:password@localhost:5432/middleware_db"

    ODOO_FILESTORE_PATH: str = ""

    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_DAYS: int = 30
    SCHOOL_ADMIN_USERNAME: str = ""
    SCHOOL_ADMIN_PASSWORD: str = ""

    @property
    def cors_origins(self) -> list[str]:
        return [origin.strip() for origin in self.CORS_ALLOW_ORIGINS.split(",") if origin.strip()]

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
                encoded_string = base64.b64encode(image_file.read()).decode('utf-8')
                return f"data:image/png;base64,{encoded_string}"
    except Exception as e:
        logger.error(f"[config] Gagal membaca file fisik: {e}")

    return None