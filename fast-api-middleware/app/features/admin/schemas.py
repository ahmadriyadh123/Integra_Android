from urllib.parse import urlsplit

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


_ELEARNING_DB_FIELDS = ("elearning_db_user", "elearning_db_secret_ref")


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


def validate_elearning_db_config(values: dict) -> None:
    if any(values.get(field) is not None for field in _ELEARNING_DB_FIELDS) and not all(
        values.get(field) is not None for field in _ELEARNING_DB_FIELDS
    ):
        raise ValueError(
            "User database dan referensi secret password e-learning harus diisi bersama."
        )


class AdminLoginRequest(BaseModel):
    username: str = Field(min_length=1, max_length=120)
    password: str = Field(min_length=1, max_length=256)


class SchoolFields(BaseModel):
    model_config = ConfigDict(extra="forbid")

    school_code: str = Field(min_length=1, max_length=50)
    school_name: str = Field(min_length=1, max_length=150)
    odoo_url: str = Field(min_length=1, max_length=500)
    odoo_db: str = Field(min_length=1, max_length=120)
    elearning_db_user: str | None = Field(default=None, min_length=1, max_length=120)
    elearning_db_secret_ref: str | None = Field(
        default=None, min_length=1, max_length=500
    )
    is_active: bool = True

    @field_validator("elearning_db_user", "elearning_db_secret_ref")
    @classmethod
    def trim_elearning_db_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip()
        if not value:
            raise ValueError("Kolom konfigurasi database e-learning tidak boleh kosong.")
        return value

    @model_validator(mode="after")
    def validate_elearning_database_settings(self) -> "SchoolFields":
        validate_elearning_db_config(self.model_dump())
        return self

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
    elearning_db_user: str | None = Field(default=None, min_length=1, max_length=120)
    elearning_db_secret_ref: str | None = Field(
        default=None, min_length=1, max_length=500
    )
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

    @field_validator("elearning_db_user", "elearning_db_secret_ref")
    @classmethod
    def trim_optional_elearning_db_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return SchoolFields.trim_elearning_db_text(value)

    @model_validator(mode="after")
    def reject_null_updates(self) -> "SchoolUpdate":
        if any(getattr(self, field) is None for field in self.model_fields_set):
            raise ValueError("Kolom yang dikirim tidak boleh bernilai null.")
        return self
