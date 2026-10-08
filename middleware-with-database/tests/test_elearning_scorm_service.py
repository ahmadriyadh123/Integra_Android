import io

import pytest
from zipfile import ZIP_STORED, ZipFile

from app.features.elearning import service as elearning_service
from app.features.elearning.service import ElearningService, _public_attachment_url


class ScormRepository:
    def __init__(self, attachment):
        self.attachment = attachment
        self.db = type(
            "TenantSession",
            (),
            {
                "info": {
                    "tenant_database": "school_db",
                    "tenant_odoo_url": "https://school.example.test",
                }
            },
        )()

    async def get_slide_content(self, slide_id):
        return {"id": slide_id, "message_main_attachment_id": 2067}

    async def get_scorm_attachment(self, slide_id):
        return self.attachment

    async def get_attachment(self, attachment_id):
        return None


@pytest.mark.asyncio
async def test_public_scorm_attachment_downloads_via_http_without_jsonrpc(
    monkeypatch,
):
    archive = io.BytesIO()
    with ZipFile(archive, "w", ZIP_STORED) as package_file:
        package_file.writestr("lesson.txt", bytes(range(256)) * 24)
    content = archive.getvalue()
    attachment = {
        "id": 2067,
        "name": "lesson.zip",
        "store_fname": "ff/attachment",
        "db_datas": None,
        "public": True,
    }
    requested_urls = []

    class HttpResponse:
        status_code = 200

        def __init__(self, body):
            self.content = body

    class HttpClient:
        def __init__(self, **kwargs):
            assert kwargs == {"timeout": 30.0, "follow_redirects": False}

        async def __aenter__(self):
            return self

        async def __aexit__(self, *_args):
            return None

        async def get(self, url):
            requested_urls.append(url)
            return HttpResponse(content)

    monkeypatch.setattr(elearning_service.httpx, "AsyncClient", HttpClient)
    package = await ElearningService(
        ScormRepository(attachment)
    ).get_scorm_package(29)

    assert package == (content, "lesson.zip", "application/zip")
    assert requested_urls == [
        "https://school.example.test/web/content/2067?download=true"
    ]


@pytest.mark.asyncio
async def test_private_attachment_is_not_fetched_over_http(monkeypatch):
    attachment = {
        "id": 2067,
        "name": "lesson.zip",
        "store_fname": None,
        "db_datas": None,
        "public": False,
    }

    class UnexpectedHttpClient:
        def __init__(self, **_kwargs):
            pytest.fail("Private SCORM attachment must not be fetched over HTTP")

    monkeypatch.setattr(
        elearning_service.httpx,
        "AsyncClient",
        UnexpectedHttpClient,
    )
    package = await ElearningService(
        ScormRepository(attachment)
    ).get_scorm_package(29)

    assert package is None


def test_public_attachment_url_rejects_invalid_tenant_url():
    assert _public_attachment_url(None, 2067) is None
    assert _public_attachment_url("file:///etc", 2067) is None
    assert _public_attachment_url("https://user:pass@example.test", 2067) is None
    assert _public_attachment_url("https://[invalid", 2067) is None
