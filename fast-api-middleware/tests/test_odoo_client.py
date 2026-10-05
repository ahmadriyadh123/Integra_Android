import xmlrpc.client
from unittest.mock import Mock

import pytest

from app.core.config import settings
from app.core.odoo_client import OdooAccessError, OdooRPCClient


def _client():
    client = OdooRPCClient(url="https://odoo.example.com", db="school_db")
    client.common = Mock()
    client.models = Mock()
    return client


def test_elevated_operation_requires_configured_service_account(monkeypatch):
    monkeypatch.setattr(settings, "ODOO_ADMIN_USER", "admin")
    monkeypatch.setattr(settings, "ODOO_ADMIN_PASS", "")
    client = _client()

    with pytest.raises(RuntimeError, match="ODOO_ADMIN_USER"):
        client.execute_kw(
            uid=17,
            password="student-password",
            model="ir.attachment",
            method="create",
            args=[{}],
            use_sudo=True,
        )

    client.common.authenticate.assert_not_called()
    client.models.execute_kw.assert_not_called()


def test_elevated_operation_does_not_fall_back_when_service_login_is_rejected(
    monkeypatch,
):
    monkeypatch.setattr(settings, "ODOO_ADMIN_USER", "integration")
    monkeypatch.setattr(settings, "ODOO_ADMIN_PASS", "service-password")
    client = _client()
    client.common.authenticate.return_value = False

    with pytest.raises(RuntimeError, match="Autentikasi akun layanan Odoo ditolak"):
        client.execute_kw(
            uid=17,
            password="student-password",
            model="ir.attachment",
            method="create",
            args=[{}],
            use_sudo=True,
        )

    client.models.execute_kw.assert_not_called()


def test_access_denial_includes_model_and_method(monkeypatch):
    monkeypatch.setattr(settings, "ODOO_ADMIN_USER", "integration")
    monkeypatch.setattr(settings, "ODOO_ADMIN_PASS", "service-password")
    client = _client()
    client.common.authenticate.return_value = 2
    client.models.execute_kw.side_effect = xmlrpc.client.Fault(
        4, "Sorry, you are not allowed to access this document."
    )

    with pytest.raises(
        OdooAccessError, match="ir.attachment.create"
    ):
        client.execute_kw(
            uid=17,
            password="student-password",
            model="ir.attachment",
            method="create",
            args=[{}],
            use_sudo=True,
        )

    call_args = client.models.execute_kw.call_args.args
    assert call_args[1:3] == (2, "service-password")
