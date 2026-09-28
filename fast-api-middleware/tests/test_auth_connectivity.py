from unittest.mock import Mock

import pytest
from fastapi import HTTPException

from app.features.auth.router import login
from app.features.auth.schemas import LoginRequest


@pytest.mark.parametrize(
    "connection_error",
    [ConnectionRefusedError("connection refused"), ConnectionResetError("connection reset")],
)
def test_login_returns_503_when_odoo_is_unreachable(connection_error):
    odoo_client = Mock()
    odoo_client.common.authenticate.side_effect = connection_error

    with pytest.raises(HTTPException) as error:
        login(LoginRequest(username="user@example.com", password="password"), odoo_client)

    assert error.value.status_code == 503


def test_login_returns_401_when_odoo_rejects_credentials():
    odoo_client = Mock()
    odoo_client.common.authenticate.return_value = False

    with pytest.raises(HTTPException) as error:
        login(LoginRequest(username="user@example.com", password="wrong"), odoo_client)

    assert error.value.status_code == 401