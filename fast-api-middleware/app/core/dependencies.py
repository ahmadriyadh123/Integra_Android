from typing import AsyncGenerator, Dict, Any
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt
from jwt.exceptions import PyJWTError

from app.core.config import settings
from app.core.odoo_client import OdooRPCClient
from app.features.auth.service import AuthService

# Scheme untuk membaca token Bearer dari Header Authorization
security_scheme = HTTPBearer(auto_error=False)


def get_odoo_client() -> OdooRPCClient:
    """
    Dependency Injection untuk menyediakan instance OdooRPCClient.
    """
    return OdooRPCClient()


async def get_current_user_credentials(
    credentials: HTTPAuthorizationCredentials = Depends(security_scheme),
) -> Dict[str, Any]:
    """
    Dependency Injection untuk mengautentikasi Token JWT dan mengekstrak 
    informasi kredensial pengguna (uid, password, partner_id, student_id, jenjang, course_id).
    """
    if not credentials or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Header Authorization tidak ditemukan. Harap melakukan login terlebih dahulu.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = credentials.credentials

    try:
        # Validasi signature dan masa berlaku token sebelum membaca identitasnya.
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM]
        )
        
        user_id: int = payload.get("uid")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token tidak valid: Kredensial User ID (uid) tidak ditemukan.",
                headers={"WWW-Authenticate": "Bearer"},
            )
            
        # Router menerima klaim yang diperlukan untuk membatasi akses data.
        return {
            "uid": payload.get("uid"),
            "sub": payload.get("sub"),
            "username": payload.get("username"),
            "password": AuthService.decrypt_odoo_password(payload.get("odoo_password", "")),
            "partner_id": payload.get("partner_id"),
            "student_id": payload.get("student_id"),
            "course_id": payload.get("course_id"),
            "jenjang": payload.get("jenjang", "sd"),
            "is_portal": payload.get("is_portal", False),
        }

    except PyJWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token autentikasi tidak valid atau telah kedaluwarsa: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )