from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, ForeignKey, Index, Integer, JSON, String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class SchoolTenant(Base):
    __tablename__ = "school_tenants"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    school_code: Mapped[str] = mapped_column(
        String(50), unique=True, index=True, nullable=False
    )
    school_name: Mapped[str] = mapped_column(String(150), nullable=False)
    odoo_url: Mapped[str] = mapped_column(String(500), nullable=False)
    odoo_db: Mapped[str] = mapped_column(
        String(120), nullable=False, unique=True
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"
    __table_args__ = (
        Index("ix_refresh_tokens_tenant_user", "tenant_id", "user_id"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    token_hash: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    tenant_id: Mapped[int] = mapped_column(
        ForeignKey("school_tenants.id", ondelete="CASCADE"), nullable=False
    )
    user_id: Mapped[int] = mapped_column(Integer, nullable=False)
    claims: Mapped[dict] = mapped_column(JSON, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    revoked_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
