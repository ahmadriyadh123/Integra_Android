from sqlalchemy import Boolean, Integer, String
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
