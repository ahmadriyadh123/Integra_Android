from collections.abc import AsyncGenerator
from typing import Any

import jwt
from fastapi import Depends, Header, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt.exceptions import PyJWTError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import (
    create_tenant_session_factory,
    get_registry_db,
)
from app.core.models import SchoolTenant

security_scheme = HTTPBearer(auto_error=False)


async def get_current_tenant(
    x_school_id: int = Header(..., alias="X-School-ID"),
    db: AsyncSession = Depends(get_registry_db),
) -> SchoolTenant:
    result = await db.execute(
        select(SchoolTenant).where(
            SchoolTenant.id == x_school_id,
            SchoolTenant.is_active.is_(True),
        )
    )
    tenant = result.scalars().first()
    if tenant is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sekolah/Tenant tidak ditemukan atau sedang tidak aktif.",
        )
    return tenant


async def get_db(
    tenant: SchoolTenant = Depends(get_current_tenant),
) -> AsyncGenerator[AsyncSession, None]:
    """Open an isolated SQLAlchemy session against the selected school's database."""
    session_factory = create_tenant_session_factory(tenant.odoo_db)
    async with session_factory() as session:
        session.info["tenant_id"] = tenant.id
        session.info["tenant_database"] = tenant.odoo_db
        session.info["tenant_odoo_url"] = tenant.odoo_url
        yield session


async def get_current_user_credentials(
    credentials: HTTPAuthorizationCredentials | None = Depends(security_scheme),
    tenant: SchoolTenant = Depends(get_current_tenant),
) -> dict[str, Any]:
    if not credentials or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Header Authorization tidak ditemukan. Harap melakukan login terlebih dahulu.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        payload = jwt.decode(
            credentials.credentials,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
        )
    except PyJWTError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token autentikasi tidak valid atau telah kedaluwarsa: {exc}",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc

    user_id = payload.get("uid")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token tidak valid: Kredensial User ID (uid) tidak ditemukan.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token_school_id = payload.get("school_id")
    if type(token_school_id) is not int:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token belum terikat ke sekolah. Silakan login kembali.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if token_school_id != tenant.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Token tidak berlaku untuk sekolah yang dipilih.",
        )

    return {
        "uid": user_id,
        "sub": payload.get("sub"),
        "username": payload.get("username"),
        "school_id": tenant.id,
        "school_db": tenant.odoo_db,
        "partner_id": payload.get("partner_id"),
        "student_id": payload.get("student_id"),
        "course_id": payload.get("course_id"),
        "jenjang": payload.get("jenjang", "sd"),
        "is_portal": payload.get("is_portal", False),
    }
