import xmlrpc.client
from types import SimpleNamespace
from unittest.mock import Mock

import pytest

from app.core.odoo_client import OdooAccessError, OdooRPCClient


def _client():
    client = OdooRPCClient(url="https://odoo.example.com", db="school_db")
    client.common = Mock()
    client.models = Mock()
    return client


def test_execute_kw_uses_authenticated_user_credentials():
    client = _client()
    client.models.execute_kw.return_value = 42

    result = client.execute_kw(
        uid=17,
        password="student-password",
        model="ir.attachment",
        method="create",
        args=[{}],
    )

    assert result == 42
    client.models.execute_kw.assert_called_once_with(
        "school_db", 17, "student-password", "ir.attachment", "create", [{}], {}
    )
    client.common.authenticate.assert_not_called()


def test_access_denial_includes_model_and_method():
    client = _client()
    client.models.execute_kw.side_effect = xmlrpc.client.Fault(
        4, "Sorry, you are not allowed to access this document."
    )

    with pytest.raises(OdooAccessError, match="ir.attachment.create"):
        client.execute_kw(
            uid=17,
            password="student-password",
            model="ir.attachment",
            method="create",
            args=[{}],
        )

    client.models.execute_kw.assert_called_once()
    client.common.authenticate.assert_not_called()


def test_tenant_factory_uses_tenant_odoo_configuration():
    tenant = SimpleNamespace(
        odoo_url="https://school.example.com/",
        odoo_db="school_database",
    )

    client = OdooRPCClient.get_client(tenant)

    assert client.url == "https://school.example.com"
    assert client.db == "school_database"


def test_client_rejects_empty_tenant_configuration():
    with pytest.raises(ValueError, match="URL dan nama database"):
        OdooRPCClient(url=" ", db="school_database")
