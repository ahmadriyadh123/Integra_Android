import secrets

from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import get_registry_db
from app.core.models import SchoolTenant
from app.features.admin.schemas import TenantPayload, TenantResponse

router = APIRouter(prefix="/admin/tenants", tags=["Administrasi Tenant"])


async def require_registry_admin(
    x_registry_admin_token: str | None = Header(default=None),
) -> None:
    configured = settings.REGISTRY_ADMIN_TOKEN
    if not configured or not x_registry_admin_token or not secrets.compare_digest(
        x_registry_admin_token, configured
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token administrasi registry tidak valid.",
        )


@router.get("", response_model=list[TenantResponse])
async def list_tenants(
    _: None = Depends(require_registry_admin),
    db: AsyncSession = Depends(get_registry_db),
):
    result = await db.execute(select(SchoolTenant).order_by(SchoolTenant.school_name))
    return result.scalars().all()


@router.put("/{school_code}", response_model=TenantResponse)
async def upsert_tenant(
    school_code: str,
    payload: TenantPayload,
    _: None = Depends(require_registry_admin),
    db: AsyncSession = Depends(get_registry_db),
):
    normalized_school_code = school_code.strip().upper()
    if normalized_school_code != payload.school_code:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Kode sekolah pada URL dan payload harus sama.",
        )
    tenant = await db.scalar(
        select(SchoolTenant).where(
            SchoolTenant.school_code == normalized_school_code
        )
    )
    if tenant is None:
        tenant = SchoolTenant(school_code=normalized_school_code)
        db.add(tenant)
    for field, value in payload.model_dump().items():
        setattr(tenant, field, value.strip() if isinstance(value, str) else value)
    await db.commit()
    await db.refresh(tenant)
    return tenant
