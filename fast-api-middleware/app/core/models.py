from sqlalchemy import Column, Integer, String, Boolean
from app.core.database import Base

class SchoolTenant(Base):
    __tablename__ = "school_tenants"

    id = Column(Integer, primary_key=True, index=True)
    school_code = Column(String, unique=True, index=True, nullable=False)
    school_name = Column(String, nullable=False)
    odoo_url = Column(String, nullable=False)  # Misal: https://sma1.sekolah.id
    odoo_db = Column(String, nullable=False)   # Misal: db_sma1
    is_active = Column(Boolean, default=True)