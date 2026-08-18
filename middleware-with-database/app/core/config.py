from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    PROJECT_NAME: str = "FastAPI Middleware Direct DB"
    
    # --- Database Config ---
    DB_HOST: str = "203.145.34.16"
    DB_PORT: int = 5432
    DB_USER: str = "kposk"
    DB_PASSWORD: str = "26KPOSK"
    DB_NAME: str = "kp-sekolah.asetkoptii.com"
    
    # --- JWT Config ---
    JWT_SECRET_KEY: str = "integra_school_secret_key_2026_super_secure_hash"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_DAYS: int = 30

    # --- Odoo Config (jika diperlukan) ---
    ODOO_URL: str = "http://203.145.34.16:8069"
    ODOO_DB: str = "kp-sekolah.asetkoptii.com"
    ODOO_FILESTORE_PATH: str = "/var/lib/odoo/.local/share/Odoo/filestore/kp-sekolah.asetkoptii.com"

    @property
    def DATABASE_URL(self) -> str:
        return f"postgresql+asyncpg://{self.DB_USER}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"

    # Gunakan model_config bawaan Pydantic v2
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",  # Mengabaikan variabel ekstra di .env tanpa melempar ValidationError
        case_sensitive=False  # Mendukung pembacaan variabel .env baik huruf kecil maupun kapital
    )

settings = Settings()