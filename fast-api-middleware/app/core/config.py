import os
from pydantic_settings import BaseSettings
from dotenv import load_dotenv

load_dotenv()

class Settings(BaseSettings):
    ODOO_URL: str = os.getenv("ODOO_URL", "http://203.145.34.16:8069")
    ODOO_DB: str = os.getenv("ODOO_DB", "kp-sekolah.asetkoptii.com")
    JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY", "secret_key_integra_school_12345")
    JWT_ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")

settings = Settings()