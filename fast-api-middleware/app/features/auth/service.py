import base64
import hashlib
import jwt
from cryptography.fernet import Fernet, InvalidToken
from fastapi import HTTPException, status
from datetime import datetime, timedelta, timezone
from app.core.config import settings

class AuthService:
    @staticmethod
    def _credential_cipher() -> Fernet:
        key = base64.urlsafe_b64encode(hashlib.sha256(settings.JWT_SECRET_KEY.encode()).digest())
        return Fernet(key)

    @staticmethod
    def encrypt_odoo_password(password: str) -> str:
        return AuthService._credential_cipher().encrypt(password.encode()).decode()

    @staticmethod
    def decrypt_odoo_password(encrypted_password: str) -> str:
        if not encrypted_password:
            return ""
        try:
            return AuthService._credential_cipher().decrypt(encrypted_password.encode()).decode()
        except InvalidToken:
            # Tangkap InvalidToken agar tidak memicu HTTP 500
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Sesi login tidak valid atau telah berakhir. Silakan login kembali."
            )

    @staticmethod
    def create_access_token(data: dict, expires_delta: timedelta = None) -> str:
        to_encode = data.copy()
        if expires_delta:
            expire = datetime.now(timezone.utc) + expires_delta
        else:
            expire = datetime.now(timezone.utc) + timedelta(days=settings.ACCESS_TOKEN_EXPIRE_DAYS)

        to_encode.update({"exp": expire})
        
        encoded_jwt = jwt.encode(
            to_encode, 
            settings.JWT_SECRET_KEY, 
            algorithm=settings.JWT_ALGORITHM
        )
        return encoded_jwt