from fastapi import Depends, HTTPException, Header, status
from typing import Dict, Any, Optional
import jwt

from app.core.config import settings
from app.core.odoo_client import OdooRPCClient

def get_odoo_client() -> OdooRPCClient:
    """
    Dependency Injection untuk menyediakan instance OdooRPCClient.
    """
    return OdooRPCClient()

def get_current_user_credentials(
    authorization: Optional[str] = Header(None, description="Header Authorization dengan format 'Bearer <token>'")
) -> Dict[str, Any]:
    """
    Dependency Injection untuk mengautentikasi Token JWT dan mengekstrak 
    'uid' serta 'password' / 'session' pengguna yang akan digunakan untuk Odoo RPC.
    """
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Header Authorization tidak ditemukan. Harap melakukan login terlebih dahulu.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        scheme, token = authorization.split()
        if scheme.lower() != "bearer":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Skema autentikasi tidak valid. Gunakan skema 'Bearer'.",
            )
            
        # Decode JWT Token menggunakan Secret Key dari Config
        payload = jwt.decode(
            token, 
            settings.JWT_SECRET_KEY, 
            algorithms=[settings.JWT_ALGORITHM]
        )
        
        uid: int = payload.get("uid") or payload.get("user_id")
        password: str = payload.get("password") or payload.get("session_id")
        partner_id: int = payload.get("partner_id")
        student_id: int = payload.get("student_id")
        jenjang: str = payload.get("jenjang", "sd")
        course_id: int = payload.get("course_id")

        if not uid:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token tidak valid: Kredensial User ID (uid) tidak ditemukan.",
            )

        return {
            "uid": int(uid),
            "password": password or "",
            "partner_id": int(partner_id) if partner_id else None,
            "student_id": int(student_id) if student_id else None,
            "jenjang": jenjang,
            "course_id": int(course_id) if course_id else None,
        }

    except (ValueError, jwt.PyJWTError) as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token autentikasi tidak valid atau telah kedaluwarsa: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )