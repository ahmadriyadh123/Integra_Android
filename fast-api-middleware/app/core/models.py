from sqlalchemy import Boolean, Column, Integer, String

from app.core.database import Base


class SchoolTenant(Base):
    __tablename__ = "school_tenants"

    id = Column(Integer, primary_key=True, index=True)
    school_code = Column(String, unique=True, index=True, nullable=False)
    school_name = Column(String, nullable=False)
    odoo_url = Column(String, nullable=False)
    odoo_db = Column(String, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
