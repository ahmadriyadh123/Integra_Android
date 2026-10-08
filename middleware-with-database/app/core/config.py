import base64
import logging
from pathlib import Path
from pydantic import AliasChoices, Field
from pydantic_settings import BaseSettings, SettingsConfigDict

logger = logging.getLogger(__name__)

class Settings(BaseSettings):
    PROJECT_NAME: str = "FastAPI Middleware Direct DB"
    
    ODOO_HOST: str
    DB_PORT: int = 5432
    DB_USER: str
    DB_PASSWORD: str
    REGISTRY_DB_NAME: str = Field(
        default="middleware_registry",
        validation_alias=AliasChoices("REGISTRY_DB_NAME", "DB_NAME"),
    )
    
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_DAYS: int = 30

    APP_ENV: str = "development"

    @property
    def DB_HOST(self) -> str:
        return self.ODOO_HOST

    @property
    def ODOO_URL(self) -> str:
        return f"https://{self.ODOO_HOST}"

    ODOO_DB: str = ""
    ODOO_FILESTORE_PATH: str = ""

    @property
    def DATABASE_URL(self) -> str:
        from sqlalchemy.engine import URL

        return URL.create(
            "postgresql+asyncpg",
            username=self.DB_USER,
            password=self.DB_PASSWORD,
            host=self.DB_HOST,
            port=self.DB_PORT,
            database=self.REGISTRY_DB_NAME,
        ).render_as_string(hide_password=False)

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",  # Mengabaikan variabel ekstra di .env tanpa melempar ValidationError
        case_sensitive=False  # Mendukung pembacaan variabel .env baik huruf kecil maupun kapital
    )

settings = Settings()

def get_attachment_path(store_fname: str, odoo_db: str | None = None) -> Path | None:
    if not store_fname or not settings.ODOO_FILESTORE_PATH:
        return None

    base_filestore = Path(settings.ODOO_FILESTORE_PATH).resolve()
    database_name = odoo_db or settings.ODOO_DB
    tenant_root = (
        (base_filestore / database_name).resolve()
        if database_name
        else base_filestore
    )
    file_path = (tenant_root / store_fname).resolve()
    try:
        file_path.relative_to(tenant_root)
    except ValueError:
        logger.warning("Attachment path escaped its tenant filestore directory.")
        return None
    return file_path


def get_attachment_base64(store_fname: str, odoo_db: str | None = None) -> str | None:
    """Membaca file gambar dari filestore tenant dan mengonversinya ke Base64."""
    file_path = get_attachment_path(store_fname, odoo_db)
    if not file_path or not file_path.is_file():
        logger.warning(f"[config] File fisik '{store_fname}' tidak ditemukan.")
        return None

    try:
        with file_path.open("rb") as image_file:
            encoded_string = base64.b64encode(image_file.read()).decode("utf-8")
            return f"data:image/png;base64,{encoded_string}"
    except OSError as exc:
        logger.error(f"[config] Gagal membaca file fisik {file_path}: {exc}")
        return None