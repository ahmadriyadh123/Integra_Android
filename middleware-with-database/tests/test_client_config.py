import asyncio

from app.core.config import settings
from app.main import client_config


def test_client_config_returns_configured_api_base_url(monkeypatch):
    api_base_url = "https://api.example.com/mobile-api/api/v1"
    monkeypatch.setattr(settings, "CLIENT_API_BASE_URL", api_base_url)

    assert asyncio.run(client_config()) == {"api_base_url": api_base_url}


def test_liveness_returns_ok():
    from app.main import liveness

    assert asyncio.run(liveness()) == {"status": "ok"}
