from pydantic import BaseModel, Field, field_validator


class TenantPayload(BaseModel):
    school_code: str = Field(min_length=1, max_length=50)
    school_name: str = Field(min_length=1, max_length=150)
    odoo_url: str = Field(min_length=1, max_length=500)
    odoo_db: str = Field(min_length=1, max_length=120)
    is_active: bool = True
    user_db: str | None = Field(default=None, max_length=120)
    secret_ref_db: str | None = Field(default=None, max_length=255)
    odoo_db_host: str = Field(min_length=1, max_length=255)
    odoo_db_port: int = Field(default=5432, ge=1, le=65535)

    @field_validator("school_code")
    @classmethod
    def normalize_school_code(cls, value: str) -> str:
        return value.strip().upper()

    @field_validator("school_name", "odoo_url", "odoo_db", "odoo_db_host")
    @classmethod
    def trim_required_text(cls, value: str) -> str:
        return value.strip()

    @field_validator("odoo_url")
    @classmethod
    def validate_odoo_url(cls, value: str) -> str:
        if not value.startswith(("http://", "https://")):
            raise ValueError("odoo_url harus menggunakan http:// atau https://.")
        return value.rstrip("/")

    @field_validator("user_db", "secret_ref_db")
    @classmethod
    def trim_optional_text(cls, value: str | None) -> str | None:
        return value.strip() if value else None


class TenantResponse(TenantPayload):
    id: int

    model_config = {"from_attributes": True}
