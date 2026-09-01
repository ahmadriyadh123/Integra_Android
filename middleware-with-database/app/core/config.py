import os
import base64
import logging
from pydantic_settings import BaseSettings, SettingsConfigDict

logger = logging.getLogger(__name__)

class Settings(BaseSettings):
    # Satu host menjadi sumber alamat Odoo dan database sekolah.
    PROJECT_NAME: str = "FastAPI Middleware Direct DB"
    
    ODOO_HOST: str
    DB_PORT: int = 5432
    DB_USER: str
    DB_PASSWORD: str
    DB_NAME: str
    
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_DAYS: int = 30

    @property
    def DB_HOST(self) -> str:
        # Odoo dan PostgreSQL berjalan pada host yang sama.
        return self.ODOO_HOST

    @property
    def ODOO_URL(self) -> str:
        return f"https://{self.ODOO_HOST}"

    ODOO_DB: str
    ODOO_FILESTORE_PATH: str

    @property
    def DATABASE_URL(self) -> str:
        return f"postgresql+asyncpg://{self.DB_USER}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",  # Mengabaikan variabel ekstra di .env tanpa melempar ValidationError
        case_sensitive=False  # Mendukung pembacaan variabel .env baik huruf kecil maupun kapital
    )

settings = Settings()

def get_attachment_base64(store_fname: str) -> str | None:
    """Membaca file gambar dari Odoo Filestore dan mengonversinya ke Base64"""
    if not store_fname:
        return None

    # 1. Normalisasi slash agar sesuai dengan OS tempat server berjalan
    clean_store_fname = os.path.normpath(store_fname)
    base_filestore = os.path.normpath(settings.ODOO_FILESTORE_PATH)

    # 2. Susun opsi pencarian path
    possible_paths = [
        # Opsi 1: Jika ODOO_FILESTORE_PATH sudah mengarah ke folder DB
        os.path.join(base_filestore, clean_store_fname),
        # Opsi 2: Jika ODOO_FILESTORE_PATH mengarah ke folder parent
        os.path.join(base_filestore, settings.ODOO_DB, clean_store_fname) if settings.ODOO_DB else "",
    ]

    file_path = None
    for p in possible_paths:
        if p and os.path.exists(p) and os.path.isfile(p):
            file_path = p
            break

    if file_path:
        try:
            with open(file_path, "rb") as image_file:
                encoded_string = base64.b64encode(image_file.read()).decode('utf-8')
                return f"data:image/png;base64,{encoded_string}"
        except Exception as e:
            logger.error(f"[config] Gagal membaca file fisik {file_path}: {e}")
            return None
    else:
        logger.warning(
            f"[config] File fisik '{store_fname}' tidak ditemukan.\n"
            f"  Lokasi yang dicari:\n"
            f"  1. {possible_paths[0]}\n"
            f"  2. {possible_paths[1]}"
        )
        return None