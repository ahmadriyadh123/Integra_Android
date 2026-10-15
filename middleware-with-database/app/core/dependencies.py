from collections.abc import AsyncGenerator
import logging
from typing import Any

import jwt
from asyncpg.exceptions import InvalidCatalogNameError
from fastapi import Depends, Header, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt.exceptions import PyJWTError
from sqlalchemy import select
from sqlalchemy.exc import DBAPIError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import (
    create_tenant_session_factory,
    get_registry_db,
)
from app.core.models import SchoolTenant

security_scheme = HTTPBearer(auto_error=False)
logger = logging.getLogger(__name__)


def _is_missing_database_error(error: BaseException) -> bool:
    original: BaseException | None = (
        error.orig if isinstance(error, DBAPIError) else error
    )
    while original is not None:
        sqlstate = getattr(original, "sqlstate", None) or getattr(
            original, "pgcode", None
        )
        if sqlstate == "3D000" or type(original).__name__ == "InvalidCatalogNameError":
            return True
        original = original.__cause__
    return False


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
    session_factory = create_tenant_session_factory(
        tenant.odoo_db_host,
        tenant.odoo_db_port,
        tenant.odoo_db,
    )
    async with session_factory() as session:
        session.info["tenant_id"] = tenant.id
        session.info["tenant_database_host"] = tenant.odoo_db_host
        session.info["tenant_database_port"] = tenant.odoo_db_port
        session.info["tenant_database"] = tenant.odoo_db
        session.info["tenant_odoo_url"] = tenant.odoo_url
        try:
            await session.connection()
        except (DBAPIError, InvalidCatalogNameError) as exc:
            if _is_missing_database_error(exc):
                logger.exception(
                    "[tenant/%s] Database tenant tidak tersedia",
                    tenant.id,
                )
                raise HTTPException(
                    status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                    detail=(
                        "Layanan sekolah sedang tidak tersedia. "
                        "Silakan coba lagi beberapa saat."
                    ),
                ) from exc
            raise
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
            detail="Sesi Anda sudah berakhir atau tidak valid. Silakan login kembali.",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc

    user_id = payload.get("uid")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sesi Anda tidak valid. Silakan login kembali.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token_school_id = payload.get("school_id")
    if type(token_school_id) is not int:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sesi Anda belum terhubung dengan sekolah. Silakan login kembali.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if token_school_id != tenant.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Akun Anda tidak sesuai dengan sekolah yang dipilih. Silakan pilih sekolah yang benar atau login kembali.",
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
