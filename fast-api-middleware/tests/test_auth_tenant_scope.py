from types import SimpleNamespace
from unittest.mock import Mock, patch

import pytest
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials

from app.core import database
from app.core.dependencies import get_current_tenant, get_current_user_credentials
from app.core.models import SchoolTenant
from app.features.auth.router import list_schools, login
from app.features.auth.schemas import LoginRequest
from app.main import app, readiness


def _school(
    school_id: int = 7,
    school_name: str = "Sekolah A",
    is_active: bool = True,
) -> SchoolTenant:
    return SchoolTenant(
        id=school_id,
        school_code=f"SDN-{school_id:03}",
        school_name=school_name,
        odoo_url="https://odoo.example.id",
        odoo_db=f"sekolah_{school_id}",
        is_active=is_active,
    )


def _credentials():
    return HTTPAuthorizationCredentials(scheme="Bearer", credentials="test-token")


@pytest.mark.asyncio
async def test_credentials_accept_token_for_selected_tenant():
    tenant = SimpleNamespace(id=7)
    with (
        patch(
            "app.core.dependencies.jwt.decode",
            return_value={"uid": 17, "school_id": 7, "username": "siswa"},
        ),
        patch(
            "app.core.dependencies.AuthService.decrypt_odoo_password",
            return_value="odoo-password",
        ),
    ):
        credentials = await get_current_user_credentials(_credentials(), tenant)

    assert credentials["school_id"] == 7
    assert credentials["uid"] == 17


@pytest.mark.asyncio
async def test_credentials_reject_token_for_different_tenant():
    tenant = SimpleNamespace(id=8)
    with patch(
        "app.core.dependencies.jwt.decode",
        return_value={"uid": 17, "school_id": 7},
    ):
        with pytest.raises(HTTPException) as error:
            await get_current_user_credentials(_credentials(), tenant)

    assert error.value.status_code == 403


@pytest.mark.asyncio
async def test_credentials_require_tenant_claim_for_legacy_token():
    tenant = SimpleNamespace(id=7)
    with patch(
        "app.core.dependencies.jwt.decode",
        return_value={"uid": 17},
    ):
        with pytest.raises(HTTPException) as error:
            await get_current_user_credentials(_credentials(), tenant)

    assert error.value.status_code == 401


def test_login_includes_selected_tenant_in_access_token():
    user_info = {
        "uid": 17,
        "username": "siswa2@gmail.com",
        "partner_id": 27,
        "student_id": 29,
        "jenjang": "sd",
        "course_id": 3,
        "course_name": "Kelas 3",
        "name": "Siswa Dua",
        "email": "siswa2@gmail.com",
    }
    token_data = {}
    with (
        patch(
            "app.features.auth.router.AuthRepository.authenticate_odoo_user",
            return_value=user_info,
        ),
        patch(
            "app.features.auth.router.AuthService.encrypt_odoo_password",
            return_value="encrypted-password",
        ),
        patch(
            "app.features.auth.router.AuthService.create_access_token",
            side_effect=lambda data: token_data.update(data) or "signed-token",
        ),
    ):
        login(
            LoginRequest(username="siswa2@gmail.com", password="test-password"),
            Mock(),
            SimpleNamespace(id=7),
        )

    assert token_data["school_id"] == 7


def test_list_schools_returns_active_school_names_and_ids():
    query = Mock()
    query.filter.return_value = query
    query.order_by.return_value = query
    query.all.return_value = [_school(7, "Sekolah A"), _school(8, "Sekolah B")]
    db = Mock()
    db.query.return_value = query

    response = list_schools(db)

    assert response["success"] is True
    assert response["data"] == [
        {"id": 7, "nama_sekolah": "Sekolah A"},
        {"id": 8, "nama_sekolah": "Sekolah B"},
    ]
    db.query.assert_called_once_with(SchoolTenant)
    query.all.assert_called_once()


def test_tenant_resolution_uses_active_database_registry():
    school = _school()
    query = Mock()
    query.filter.return_value = query
    query.first.return_value = school
    db = Mock()
    db.query.return_value = query

    assert get_current_tenant(7, db) is school
    query.first.assert_called_once()


def test_tenant_resolution_rejects_unknown_or_inactive_school():
    query = Mock()
    query.filter.return_value = query
    query.first.return_value = None
    db = Mock()
    db.query.return_value = query

    with pytest.raises(HTTPException) as error:
        get_current_tenant(8, db)

    assert error.value.status_code == 404


def test_registry_uses_dedicated_connection_settings():
    assert database.registry_url.drivername == "postgresql+psycopg2"
    assert not hasattr(database.settings, "DATABASE_URL")


def test_readiness_reports_active_database_tenant_count(monkeypatch):
    db = Mock()
    db.__enter__ = Mock(return_value=db)
    db.__exit__ = Mock(return_value=None)
    query = Mock()
    query.filter.return_value = query
    query.count.return_value = 2
    db.query.return_value = query
    monkeypatch.setattr("app.main.SessionLocal", lambda: db)

    assert readiness() == {"status": "ready", "configured_schools": 2}


def test_readiness_rejects_missing_active_tenant(monkeypatch):
    db = Mock()
    db.__enter__ = Mock(return_value=db)
    db.__exit__ = Mock(return_value=None)
    query = Mock()
    query.filter.return_value = query
    query.count.return_value = 0
    db.query.return_value = query
    monkeypatch.setattr("app.main.SessionLocal", lambda: db)

    with pytest.raises(HTTPException) as error:
        readiness()

    assert error.value.status_code == 503


def test_fast_api_does_not_mount_removed_admin_routes():
    assert not any(path.startswith("/api/v1/admin") for path in app.openapi()["paths"])
