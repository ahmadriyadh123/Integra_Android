from types import SimpleNamespace
from unittest.mock import Mock, patch

import pytest
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials

from app.core.dependencies import get_current_user_credentials
from app.features.auth.router import list_schools, login
from app.features.auth.schemas import LoginRequest


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
            LoginRequest(username="siswa2@gmail.com", password="password"),
            Mock(),
            SimpleNamespace(id=7),
        )

    assert token_data["school_id"] == 7


def test_list_schools_returns_active_school_names_and_ids():
    active_school = SimpleNamespace(id=7, school_name="Sekolah A")
    query = Mock()
    query.filter.return_value = query
    query.order_by.return_value = query
    query.all.return_value = [active_school]
    db = Mock()
    db.query.return_value = query

    response = list_schools(db)

    assert response["success"] is True
    assert response["data"] == [{"id": 7, "nama_sekolah": "Sekolah A"}]
    db.query.assert_called_once()
    query.filter.assert_called_once()
    query.order_by.assert_called_once()