import os
import base64
import logging
from pydantic_settings import BaseSettings, SettingsConfigDict

logger = logging.getLogger(__name__)

class Settings(BaseSettings):
    PROJECT_NAME: str = "FastAPI Middleware Odoo RPC"
    
    ODOO_HOST: str
    ODOO_DB: str
    ODOO_ADMIN_USER: str = "admin"
    ODOO_ADMIN_PASS: str = ""
    ODOO_FILESTORE_PATH: str = ""
    
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_DAYS: int = 30

    @property
    def ODOO_URL(self) -> str:
        return f"http://{self.ODOO_HOST}:8069"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

settings = Settings()

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