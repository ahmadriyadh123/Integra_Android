import jwt
from datetime import datetime, timedelta, timezone
from typing import Dict, Any
from app.core.config import settings

class AuthService:
    @staticmethod
    def create_access_token(data: dict, expires_delta: timedelta = None) -> str:
        """
        Membuat Token JWT yang menyimpan 'uid' dan 'password' (atau session identifier)
        agar FastAPI dapat menggunakannya saat memanggil Odoo RPC atas nama user tersebut.
        """
        to_encode = data.copy()
        if expires_delta:
            expire = datetime.now(timezone.utc) + expires_delta
        else:
            expire = datetime.now(timezone.utc) + timedelta(days=30)  # Token berlaku 30 hari

        to_encode.update({"exp": expire})
        
        encoded_jwt = jwt.encode(
            to_encode, 
            settings.JWT_SECRET_KEY, 
            algorithm=settings.JWT_ALGORITHM
        )
        return encoded_jwt