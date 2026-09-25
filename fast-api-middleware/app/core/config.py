import os
import base64
import logging
from pydantic_settings import BaseSettings, SettingsConfigDict

logger = logging.getLogger(__name__)

class Settings(BaseSettings):
    PROJECT_NAME: str = "FastAPI Middleware Odoo RPC"
    APP_ENV: str = "development"
    CORS_ALLOW_ORIGINS: str = ""
    
    ODOO_HOST: str
    ODOO_DB: str
    ODOO_SCHEME: str = "http"
    ODOO_PORT: int = 8069
    ODOO_ADMIN_USER: str = "admin"
    ODOO_ADMIN_PASS: str = ""
    ODOO_FILESTORE_PATH: str = ""
    
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_DAYS: int = 30

    @property
    def ODOO_URL(self) -> str:
        return f"{self.ODOO_SCHEME}://{self.ODOO_HOST}:{self.ODOO_PORT}"

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
    if settings.ODOO_ADMIN_PASS in {"", "admin_password_here"}:
        raise ValueError("ODOO_ADMIN_PASS production harus diisi dengan secret yang valid")

def get_attachment_base64(store_fname: str) -> str | None:
    """Membaca file gambar dari Odoo Filestore dan mengonversinya ke Base64"""
    if not store_fname or not settings.ODOO_FILESTORE_PATH:
        return None

    try:
        # Normalisasi path sesuai OS
        clean_store_fname = os.path.normpath(store_fname)
        base_filestore = os.path.normpath(settings.ODOO_FILESTORE_PATH)

        # Coba path dengan DB name
        file_path = os.path.join(base_filestore, settings.ODOO_DB, clean_store_fname)
        
        if os.path.exists(file_path) and os.path.isfile(file_path):
            with open(file_path, "rb") as image_file:
                encoded_string = base64.b64encode(image_file.read()).decode('utf-8')
                return f"data:image/png;base64,{encoded_string}"
    except Exception as e:
        logger.error(f"[config] Gagal membaca file fisik: {e}")
    
    return None