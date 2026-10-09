from threading import Thread
from xmlrpc.server import SimpleXMLRPCRequestHandler, SimpleXMLRPCServer
from unittest.mock import MagicMock, Mock

import jwt
import pytest
from fastapi import HTTPException, Response
from pydantic import ValidationError
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.config import settings
from app.core.database import Base
from app.core.models import SchoolAdminAccount, SchoolTenant
from app.features.admin.bootstrap import seed_initial_admin
from app.features.admin import router as admin_router
from app.features.admin.schemas import SchoolCreate, SchoolUpdate
from app.features.admin.security import hash_password, verify_password


def test_school_create_normalizes_code_and_url():
    school = SchoolCreate(
        school_code=" sdn-001 ",
        school_name=" SD Negeri 1 ",
        odoo_url="https://odoo.example.id/",
        odoo_db=" sekolah_db ",
    )

    assert school.school_code == "SDN-001"
    assert school.school_name == "SD Negeri 1"
    assert school.odoo_url == "https://odoo.example.id"
    assert school.odoo_db == "sekolah_db"


def test_school_tenant_maps_elearning_credentials_to_registry_column_names():
    columns = SchoolTenant.__table__.columns

    assert columns.user_db is not None
    assert columns.secret_ref_db is not None
    assert SchoolTenant.elearning_db_user.property.columns[0].name == "user_db"
    assert (
        SchoolTenant.elearning_db_secret_ref.property.columns[0].name
        == "secret_ref_db"
    )


def test_school_create_rejects_invalid_odoo_url():
    with pytest.raises(ValidationError):
        SchoolCreate(
            school_code="SDN-001",
            school_name="SD Negeri 1",
            odoo_url="javascript:alert(1)",
            odoo_db="sekolah_db",
        )


def test_school_create_accepts_elearning_database_user_and_secret_reference():
    school = SchoolCreate(
        school_code="SDN-001",
        school_name="SD Negeri 1",
        odoo_url="https://odoo.example.id",
        odoo_db="odoo_school",
        elearning_db_user="elearning_reader",
        elearning_db_secret_ref="schools/SDN-001/postgres",
    )

    assert school.elearning_db_user == "elearning_reader"
    assert school.elearning_db_secret_ref == "schools/SDN-001/postgres"


def test_school_create_requires_user_and_secret_reference_together():
    with pytest.raises(ValidationError, match="referensi secret"):
        SchoolCreate(
            school_code="SDN-001",
            school_name="SD Negeri 1",
            odoo_url="https://odoo.example.id",
            odoo_db="odoo_school",
            elearning_db_user="elearning_reader",
        )


def test_school_create_rejects_plaintext_elearning_database_password():
    with pytest.raises(ValidationError, match="elearning_db_password"):
        SchoolCreate(
            school_code="SDN-001",
            school_name="SD Negeri 1",
            odoo_url="https://odoo.example.id",
            odoo_db="odoo_school",
            elearning_db_password="must-not-be-stored",
        )


def test_school_update_trims_elearning_database_credentials():
    update = SchoolUpdate(
        elearning_db_user=" elearning_reader ",
        elearning_db_secret_ref=" schools/SDN-001/postgres ",
    )
    assert update.elearning_db_user == "elearning_reader"
    assert update.elearning_db_secret_ref == "schools/SDN-001/postgres"


def test_admin_school_response_never_exposes_secret_reference():
    school = type(
        "School",
        (),
        {
            "id": 7,
            "school_code": "SDN-001",
            "school_name": "SD Negeri 1",
            "odoo_url": "https://odoo.example.id",
            "odoo_db": "odoo_school",
            "elearning_db_user": "elearning_reader",
            "elearning_db_secret_ref": "schools/SDN-001/postgres",
            "is_active": True,
        },
    )()

    result = admin_router._school_data(school)

    assert result["elearning_db_secret_configured"] is True
    assert "elearning_db_secret_ref" not in result
    assert "schools/SDN-001/postgres" not in repr(result)


def test_school_update_rejects_null_values():
    with pytest.raises(ValidationError):
        SchoolUpdate(is_active=None)


def test_admin_session_uses_http_only_same_site_cookie(monkeypatch):
    monkeypatch.setattr(settings, "JWT_SECRET_KEY", "test-jwt-secret")
    monkeypatch.setattr(settings, "APP_ENV", "development")
    response = Response()
    account = SchoolAdminAccount(
        username="admin",
        password_hash=hash_password("test-password-long"),
        is_active=True,
    )
    query = Mock()
    query.filter.return_value = query
    query.first.return_value = account
    db = Mock()
    db.query.return_value = query

    result = admin_router.create_admin_session(
        admin_router.AdminLoginRequest(
            username=" Admin ",
            password="test-password-long",
        ),
        response,
        db,
    )

    cookie = response.headers["set-cookie"]
    assert result["success"] is True
    assert "HttpOnly" in cookie
    assert "SameSite=strict" in cookie
    token = cookie.split(";", 1)[0].split("=", 1)[1]
    claims = jwt.decode(token, "test-jwt-secret", algorithms=["HS256"])
    assert claims["purpose"] == "school_admin"
    assert claims["sub"] == "admin"


def test_admin_session_rejects_invalid_credentials(monkeypatch):
    account = SchoolAdminAccount(
        username="admin",
        password_hash=hash_password("test-password-long"),
        is_active=True,
    )
    query = Mock()
    query.filter.return_value = query
    query.first.return_value = account
    db = Mock()
    db.query.return_value = query

    with pytest.raises(HTTPException) as error:
        admin_router.create_admin_session(
            admin_router.AdminLoginRequest(
                username="admin",
                password="wrong-password-value",
            ),
            Response(),
            db,
        )

    assert error.value.status_code == 401


def test_school_api_rejects_missing_admin_session():
    with pytest.raises(HTTPException) as error:
        admin_router.require_school_admin(None, Mock())

    assert error.value.status_code == 401


def test_admin_password_is_stored_as_a_verifiable_hash():
    password = "long-secure-admin-password"
    encoded_hash = hash_password(password)

    assert password not in encoded_hash
    assert verify_password(password, encoded_hash)
    assert not verify_password("incorrect-password", encoded_hash)
    assert not verify_password(password, "invalid-hash")


def test_admin_password_hash_requires_a_long_password():
    with pytest.raises(ValueError, match="minimal 12 karakter"):
        hash_password("short")


def test_initial_admin_is_hashed_and_seeded_only_once(monkeypatch):
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(bind=engine)
    test_session = sessionmaker(bind=engine)
    monkeypatch.setattr(settings, "SCHOOL_ADMIN_USERNAME", "First.Admin")
    monkeypatch.setattr(settings, "SCHOOL_ADMIN_PASSWORD", "initial-long-password")

    try:
        with test_session() as db:
            assert seed_initial_admin(db) is True
            account = db.query(SchoolAdminAccount).one()
            assert account.username == "first.admin"
            assert account.password_hash != "initial-long-password"
            assert verify_password("initial-long-password", account.password_hash)

        monkeypatch.setattr(settings, "SCHOOL_ADMIN_USERNAME", "replacement")
        monkeypatch.setattr(settings, "SCHOOL_ADMIN_PASSWORD", "replacement-password")
        with test_session() as db:
            assert seed_initial_admin(db) is False
            account = db.query(SchoolAdminAccount).one()
            assert account.username == "first.admin"
            assert verify_password("initial-long-password", account.password_hash)
            assert not verify_password("replacement-password", account.password_hash)
    finally:
        engine.dispose()


def test_odoo_connection_check_returns_version_and_latency(monkeypatch):
    school = type(
        "School",
        (),
        {"id": 7, "odoo_url": "https://odoo.example.id"},
    )()
    common = Mock()
    common.version.return_value = {"server_version": "17.0"}
    proxy = MagicMock()
    proxy.__enter__.return_value = common
    proxy.__exit__.return_value = False
    monkeypatch.setattr(admin_router, "ServerProxy", Mock(return_value=proxy))

    result = admin_router._check_odoo_connection(school)

    assert result["school_id"] == 7
    assert result["connected"] is True
    assert result["odoo_version"] == "17.0"
    assert result["latency_ms"] >= 0
    assert result["checked_at"]
    assert result["message"] == "Server Odoo merespons."


def test_odoo_connection_check_returns_safe_timeout_message(monkeypatch):
    school = type(
        "School",
        (),
        {"id": 8, "odoo_url": "http://odoo.example.id"},
    )()
    proxy = MagicMock()
    proxy.__enter__.side_effect = TimeoutError()
    proxy.__exit__.return_value = False
    monkeypatch.setattr(admin_router, "ServerProxy", Mock(return_value=proxy))

    result = admin_router._check_odoo_connection(school)

    assert result["school_id"] == 8
    assert result["connected"] is False
    assert result["odoo_version"] is None
    assert result["message"] == "Waktu tunggu koneksi Odoo habis."


def test_odoo_connection_check_calls_common_version():
    class OdooXmlRpcHandler(SimpleXMLRPCRequestHandler):
        rpc_paths = ("/xmlrpc/2/common",)

    server = SimpleXMLRPCServer(
        ("127.0.0.1", 0),
        requestHandler=OdooXmlRpcHandler,
        logRequests=False,
        allow_none=True,
    )
    server.register_function(lambda: {"server_version": "17.0"}, "version")
    thread = Thread(target=server.serve_forever, daemon=True)
    thread.start()
    school = type(
        "School",
        (),
        {
            "id": 9,
            "odoo_url": f"http://127.0.0.1:{server.server_address[1]}",
        },
    )()

    try:
        result = admin_router._check_odoo_connection(school)
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=2)

    assert result["connected"] is True
    assert result["odoo_version"] == "17.0"


def test_check_school_connection_checks_only_requested_school(monkeypatch):
    school = type("School", (), {"id": 12})()
    query = Mock()
    query.filter.return_value = query
    query.first.return_value = school
    db = Mock()
    db.query.return_value = query
    checked_connection = {
        "school_id": 12,
        "connected": True,
        "latency_ms": 18,
        "odoo_version": "17.0",
    }
    monkeypatch.setattr(
        admin_router,
        "_check_odoo_connection",
        Mock(return_value=checked_connection),
    )

    result = admin_router.check_school_connection(12, "admin", db)

    assert result == {"success": True, "data": checked_connection}
    query.first.assert_called_once()
    admin_router._check_odoo_connection.assert_called_once_with(school)


def test_check_school_connection_returns_not_found_for_unknown_school():
    query = Mock()
    query.filter.return_value = query
    query.first.return_value = None
    db = Mock()
    db.query.return_value = query

    with pytest.raises(HTTPException) as error:
        admin_router.check_school_connection(999, "admin", db)

    assert error.value.status_code == 404
