import pytest
from fastapi import HTTPException

from app.core import config
from app.features.admin.router import require_registry_admin


@pytest.mark.asyncio
async def test_registry_admin_requires_configured_token(monkeypatch):
    monkeypatch.setattr(config.settings, "REGISTRY_ADMIN_TOKEN", "secret-token")

    await require_registry_admin("secret-token")

    with pytest.raises(HTTPException) as error:
        await require_registry_admin("wrong-token")
    assert error.value.status_code == 401


@pytest.mark.asyncio
async def test_registry_admin_rejects_missing_token(monkeypatch):
    monkeypatch.setattr(config.settings, "REGISTRY_ADMIN_TOKEN", "")

    with pytest.raises(HTTPException) as error:
        await require_registry_admin(None)
    assert error.value.status_code == 401
