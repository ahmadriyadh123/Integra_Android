from pydantic_settings import BaseSettings, SettingsConfigDict

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
        # SQLAlchemy memakai URL ini untuk membuat koneksi async PostgreSQL.
        return f"postgresql+asyncpg://{self.DB_USER}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",  # Mengabaikan variabel ekstra di .env tanpa melempar ValidationError
        case_sensitive=False  # Mendukung pembacaan variabel .env baik huruf kecil maupun kapital
    )

settings = Settings()