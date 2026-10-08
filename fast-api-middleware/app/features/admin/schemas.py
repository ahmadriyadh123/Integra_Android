from urllib.parse import urlsplit

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


def validate_odoo_url(value: str) -> str:
    value = value.strip().rstrip("/")
    parsed = urlsplit(value)
    if (
        parsed.scheme not in {"http", "https"}
        or not parsed.hostname
        or parsed.username
        or parsed.password
    ):
        raise ValueError("URL Odoo harus berupa alamat http/https yang valid.")
    return value


class AdminLoginRequest(BaseModel):
    username: str = Field(min_length=1, max_length=120)
    password: str = Field(min_length=1, max_length=256)


class SchoolFields(BaseModel):
    school_code: str = Field(min_length=1, max_length=50)
    school_name: str = Field(min_length=1, max_length=150)
    odoo_url: str = Field(min_length=1, max_length=500)
    odoo_db: str = Field(min_length=1, max_length=120)
    is_active: bool = True

    @field_validator("school_code")
    @classmethod
    def normalize_school_code(cls, value: str) -> str:
        value = value.strip().upper()
        if not value:
            raise ValueError("Kode sekolah wajib diisi.")
        return value

    @field_validator("school_name", "odoo_db")
    @classmethod
    def trim_required_text(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("Kolom ini wajib diisi.")
        return value

    @field_validator("odoo_url")
    @classmethod
    def validate_url(cls, value: str) -> str:
        return validate_odoo_url(value)


class SchoolCreate(SchoolFields):
    pass


class SchoolUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    school_code: str | None = Field(default=None, min_length=1, max_length=50)
    school_name: str | None = Field(default=None, min_length=1, max_length=150)
    odoo_url: str | None = Field(default=None, min_length=1, max_length=500)
    odoo_db: str | None = Field(default=None, min_length=1, max_length=120)
    is_active: bool | None = None

    @field_validator("school_code")
    @classmethod
    def normalize_school_code(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip().upper()
        if not value:
            raise ValueError("Kode sekolah wajib diisi.")
        return value

    @field_validator("school_name", "odoo_db")
    @classmethod
    def trim_optional_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip()
        if not value:
            raise ValueError("Kolom ini wajib diisi.")
        return value

    @field_validator("odoo_url")
    @classmethod
    def validate_optional_url(cls, value: str | None) -> str | None:
        return validate_odoo_url(value) if value is not None else None

    @model_validator(mode="after")
    def reject_null_updates(self) -> "SchoolUpdate":
        if any(getattr(self, field) is None for field in self.model_fields_set):
            raise ValueError("Kolom yang dikirim tidak boleh bernilai null.")
        return self
