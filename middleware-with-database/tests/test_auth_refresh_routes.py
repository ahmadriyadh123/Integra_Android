from types import SimpleNamespace
from unittest.mock import AsyncMock, Mock

import pytest
from fastapi import HTTPException

from app.features.auth import router as auth_router
from app.features.auth.refresh_tokens import RefreshTokenRepository
from app.features.auth.repository import AuthRepository
from app.features.auth.schemas import RefreshRequest
from app.features.auth.service import AuthService


@pytest.mark.asyncio
async def test_refresh_route_rotates_token_for_an_active_user(monkeypatch):
    monkeypatch.setattr(
        RefreshTokenRepository,
        "rotate",
        AsyncMock(
            return_value=(
                "rotated-refresh-token",
                {"uid": 42, "school_id": 3, "username": "student"},
            )
        ),
    )
    monkeypatch.setattr(
        AuthRepository, "is_user_active", AsyncMock(return_value=True)
    )
    monkeypatch.setattr(
        AuthService, "create_access_token", Mock(return_value="new-access-token")
    )

    result = await auth_router.refresh_token(
        RefreshRequest(refresh_token="old-refresh-token"),
        db=AsyncMock(),
        registry_db=AsyncMock(),
        tenant=SimpleNamespace(id=3),
    )

    assert result["success"] is True
    assert result["data"].access_token == "new-access-token"
    assert result["data"].refresh_token == "rotated-refresh-token"


@pytest.mark.asyncio
async def test_refresh_route_rejects_a_disabled_user_and_revokes_rotation(
    monkeypatch,
):
    revoke = AsyncMock()
    monkeypatch.setattr(
        RefreshTokenRepository,
        "rotate",
        AsyncMock(
            return_value=(
                "rotated-refresh-token",
                {"uid": 42, "school_id": 3, "username": "student"},
            )
        ),
    )
    monkeypatch.setattr(RefreshTokenRepository, "revoke", revoke)
    monkeypatch.setattr(
        AuthRepository, "is_user_active", AsyncMock(return_value=False)
    )

    with pytest.raises(HTTPException) as error:
        await auth_router.refresh_token(
            RefreshRequest(refresh_token="old-refresh-token"),
            db=AsyncMock(),
            registry_db=AsyncMock(),
            tenant=SimpleNamespace(id=3),
        )

    assert error.value.status_code == 401
    revoke.assert_awaited_once()


@pytest.mark.asyncio
async def test_refresh_route_rejects_a_replayed_refresh_token(monkeypatch):
    monkeypatch.setattr(
        RefreshTokenRepository,
        "rotate",
        AsyncMock(return_value=None),
    )

    with pytest.raises(HTTPException) as error:
        await auth_router.refresh_token(
            RefreshRequest(refresh_token="replayed-token"),
            db=AsyncMock(),
            registry_db=AsyncMock(),
            tenant=SimpleNamespace(id=3),
        )

    assert error.value.status_code == 401
