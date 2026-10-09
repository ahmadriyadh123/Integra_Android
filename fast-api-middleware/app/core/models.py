from datetime import datetime, timezone

from sqlalchemy import Boolean, Column, DateTime, Integer, String

from app.core.database import Base


class SchoolTenant(Base):
    __tablename__ = "school_tenants"

    id = Column(Integer, primary_key=True, index=True)
    school_code = Column(String, unique=True, index=True, nullable=False)
    school_name = Column(String, nullable=False)
    odoo_url = Column(String, nullable=False)  # Misal: https://sma1.sekolah.id
    odoo_db = Column(String, nullable=False)   # Misal: db_sma1
    elearning_db_user = Column("user_db", String(120), nullable=True)
    elearning_db_secret_ref = Column("secret_ref_db", String(500), nullable=True)
    is_active = Column(Boolean, default=True)


class SchoolAdminAccount(Base):
    __tablename__ = "school_admin_accounts"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(120), unique=True, index=True, nullable=False)
    password_hash = Column(String(256), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )