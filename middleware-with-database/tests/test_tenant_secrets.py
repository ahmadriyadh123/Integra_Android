import json

import pytest

from app.core import tenant_secrets


def test_reads_tenant_username_and_password_from_secret_file(tmp_path, monkeypatch):
    secret_file = tmp_path / "tenant-secrets.json"
    secret_file.write_text(
        json.dumps(
            {
                "tenant/bogor/postgresql": {
                    "username": "mwd_bogor",
                    "password": "not-stored-in-registry",
                }
            }
        ),
        encoding="utf-8",
    )
    monkeypatch.setattr(
        tenant_secrets.settings,
        "TENANT_SECRETS_FILE",
        str(secret_file),
    )

    assert tenant_secrets.get_tenant_credentials(
        "tenant/bogor/postgresql"
    ) == {
        "username": "mwd_bogor",
        "password": "not-stored-in-registry",
    }


@pytest.mark.parametrize("secret_ref", [None, "missing"])
def test_missing_tenant_secret_is_rejected(secret_ref, tmp_path, monkeypatch):
    secret_file = tmp_path / "tenant-secrets.json"
    secret_file.write_text("{}", encoding="utf-8")
    monkeypatch.setattr(
        tenant_secrets.settings,
        "TENANT_SECRETS_FILE",
        str(secret_file),
    )

    with pytest.raises(tenant_secrets.TenantSecretError):
        tenant_secrets.get_tenant_credentials(secret_ref)
