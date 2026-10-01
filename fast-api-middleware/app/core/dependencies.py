from typing import Dict, Any
from fastapi import Header, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
import jwt
from jwt.exceptions import PyJWTError

from app.core.database import get_db
from app.core.config import settings
from app.core.models import SchoolTenant
from app.core.odoo_client import OdooRPCClient
from app.features.auth.service import AuthService

security_scheme = HTTPBearer(auto_error=False)

def get_current_tenant(
    x_school_id: int = Header(..., alias="X-School-ID"),
    db: Session = Depends(get_db)
) -> SchoolTenant:
    """Dependency Injection untuk menyelesaikan identitas Tenant Sekolah dari Header"""
    tenant = db.query(SchoolTenant).filter(
        SchoolTenant.id == x_school_id, 
        SchoolTenant.is_active == True
    ).first()
    
    if not tenant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sekolah/Tenant tidak ditemukan atau sedang tidak aktif."
        )
    return tenant

def get_odoo_client(
    tenant: SchoolTenant = Depends(get_current_tenant)
) -> OdooRPCClient:
    """
    Dependency Injection untuk menyediakan instance OdooRPCClient dinamis
    sesuai dengan Tenant Sekolah yang ter-resolve.
    """
    return OdooRPCClient.get_client(tenant)

async def get_current_user_credentials(
    credentials: HTTPAuthorizationCredentials = Depends(security_scheme),
) -> Dict[str, Any]:
    if not credentials or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Header Authorization tidak ditemukan. Harap melakukan login terlebih dahulu.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token = credentials.credentials
    try:
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

        return {
            "uid": payload.get("uid"),
            "sub": payload.get("sub"),
            "username": payload.get("username"),
            "password": AuthService.decrypt_odoo_password(payload.get("odoo_password", "")),
            "school_id": payload.get("school_id"), # Menyimpan school_id dalam claim JWT
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