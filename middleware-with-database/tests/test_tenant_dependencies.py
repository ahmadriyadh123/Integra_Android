import jwt
import pytest
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials
from types import SimpleNamespace

from fastapi.testclient import TestClient

from app.core import database
from app.core.config import settings
from app.core.dependencies import (
    get_current_tenant,
    get_current_user_credentials,
    get_registry_db,
)
from app.core.models import SchoolTenant
from app.core.config import get_attachment_path
from app.main import app


class TenantScalars:
    def __init__(self, tenant):
        self.tenant = tenant

    def scalars(self):
        return self

    def first(self):
        return self.tenant

    def all(self):
        return [self.tenant] if self.tenant else []


class RegistrySession:
    def __init__(self, tenant):
        self.tenant = tenant

    async def execute(self, _query):
        return TenantScalars(self.tenant)


@pytest.fixture
def tenant():
    return SchoolTenant(
        id=7,
        school_code="SEKOLAH-001",
        school_name="Sekolah Alam Bogor",
        odoo_url="https://sekolahalambogor.sch.id",
        odoo_db="sekolahalambogor.sch.id",
        is_active=True,
    )


def test_tenant_model_matches_registry_columns():
    assert set(SchoolTenant.__table__.columns.keys()) == {
        "id",
        "school_code",
        "school_name",
        "odoo_url",
        "odoo_db",
        "is_active",
    }


def test_schools_endpoint_is_available_without_a_tenant_header(tenant):
    async def override_registry_db():
        yield RegistrySession(tenant)

    app.dependency_overrides[get_registry_db] = override_registry_db
    try:
        response = TestClient(app).get("/api/v1/auth/schools")
    finally:
        app.dependency_overrides.pop(get_registry_db, None)

    assert response.status_code == 200
    assert response.json()["data"] == [
        {"id": 7, "nama_sekolah": "Sekolah Alam Bogor"}
    ]


@pytest.mark.asyncio
async def test_resolves_active_school_from_header_value(tenant):
    resolved = await get_current_tenant(
        x_school_id=7,
        db=RegistrySession(tenant),
    )

    assert resolved is tenant


@pytest.mark.asyncio
async def test_unknown_school_is_rejected():
    with pytest.raises(HTTPException) as error:
        await get_current_tenant(
            x_school_id=404,
            db=RegistrySession(None),
        )

    assert error.value.status_code == 404


@pytest.mark.asyncio
async def test_jwt_must_match_selected_school(tenant):
    token = jwt.encode(
        {"uid": 12, "school_id": 8},
        settings.JWT_SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM,
    )

    with pytest.raises(HTTPException) as error:
        await get_current_user_credentials(
            credentials=HTTPAuthorizationCredentials(
                scheme="Bearer",
                credentials=token,
            ),
            tenant=tenant,
        )

    assert error.value.status_code == 403


@pytest.mark.asyncio
async def test_credentials_include_selected_tenant(tenant):
    token = jwt.encode(
        {"uid": 12, "school_id": tenant.id, "username": "siswa"},
        settings.JWT_SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM,
    )

    credentials = await get_current_user_credentials(
        credentials=HTTPAuthorizationCredentials(
            scheme="Bearer",
            credentials=token,
        ),
        tenant=tenant,
    )

    assert credentials["school_id"] == tenant.id
    assert credentials["school_db"] == tenant.odoo_db


def test_tenant_engine_targets_school_database(monkeypatch):
    monkeypatch.setattr(
        database,
        "settings",
        SimpleNamespace(
            DATABASE_URL=(
                "postgresql+asyncpg://user:password@localhost:5432/"
                "middleware_registry"
            )
        ),
    )

    engine = database.get_tenant_engine("sekolahalambogor.sch.id")
    assert engine.url.database == "sekolahalambogor.sch.id"

    database._tenant_engines.pop("sekolahalambogor.sch.id", None)
    import asyncio

    asyncio.run(engine.dispose())


def test_tenant_database_name_rejects_invalid_characters():
    with pytest.raises(ValueError, match="Nama database tenant tidak valid"):
        database.get_tenant_engine("school/db")


def test_filestore_path_stays_within_selected_tenant(tmp_path, monkeypatch):
    monkeypatch.setattr(settings, "ODOO_FILESTORE_PATH", str(tmp_path))
    monkeypatch.setattr(settings, "ODOO_DB", "legacy_school")

    tenant_path = get_attachment_path("ab/file.zip", "odoo_sma7")
    escaped_path = get_attachment_path("../../legacy_school/file.zip", "odoo_sma7")

    assert tenant_path == tmp_path.resolve() / "odoo_sma7" / "ab" / "file.zip"
    assert escaped_path is None
