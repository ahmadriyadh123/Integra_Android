import secrets
import socket
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from xml.parsers.expat import ExpatError
from xmlrpc.client import Fault, ProtocolError, SafeTransport, ServerProxy, Transport
from urllib.parse import urlsplit

import jwt
from fastapi import APIRouter, Cookie, Depends, HTTPException, Response, status
from jwt.exceptions import PyJWTError
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.models import SchoolAdminAccount, SchoolTenant
from app.features.admin.schemas import AdminLoginRequest, SchoolCreate, SchoolUpdate
from app.features.admin.security import (
    hash_password,
    normalize_username,
    verify_password,
)

router = APIRouter(prefix="/admin", tags=["Administrasi Sekolah"])
SESSION_COOKIE = "school_admin_session"
SESSION_DURATION = timedelta(hours=8)
_DUMMY_PASSWORD_HASH = hash_password(secrets.token_urlsafe(32))
ODOO_PROBE_TIMEOUT_SECONDS = 5
ODOO_PROBE_WORKERS = 5


class _TimeoutTransport(Transport):
    def __init__(self, timeout: int):
        super().__init__()
        self.timeout = timeout

    def make_connection(self, host: str):
        connection = super().make_connection(host)
        connection.timeout = self.timeout
        return connection


class _TimeoutSafeTransport(SafeTransport):
    def __init__(self, timeout: int):
        super().__init__()
        self.timeout = timeout

    def make_connection(self, host: str):
        connection = super().make_connection(host)
        connection.timeout = self.timeout
        return connection


def _check_odoo_connection(school: SchoolTenant) -> dict:
    checked_at = datetime.now(timezone.utc)
    started_at = time.monotonic()
    try:
        parsed_url = urlsplit(school.odoo_url)
        transport = (
            _TimeoutSafeTransport(ODOO_PROBE_TIMEOUT_SECONDS)
            if parsed_url.scheme == "https"
            else _TimeoutTransport(ODOO_PROBE_TIMEOUT_SECONDS)
        )
        with ServerProxy(
            f"{school.odoo_url.rstrip('/')}/xmlrpc/2/common",
            transport=transport,
            allow_none=True,
        ) as common:
            version = common.version()
        return {
            "school_id": school.id,
            "connected": True,
            "latency_ms": round((time.monotonic() - started_at) * 1000),
            "odoo_version": version.get("server_version")
            if isinstance(version, dict)
            else None,
            "message": "Server Odoo merespons.",
            "checked_at": checked_at.isoformat(),
        }
    except (
        OSError,
        socket.timeout,
        Fault,
        ProtocolError,
        ExpatError,
        ValueError,
    ) as exc:
        return {
            "school_id": school.id,
            "connected": False,
            "latency_ms": round((time.monotonic() - started_at) * 1000),
            "odoo_version": None,
            "message": _connection_error_message(exc),
            "checked_at": checked_at.isoformat(),
        }


def _connection_error_message(error: Exception) -> str:
    if isinstance(error, (TimeoutError, socket.timeout)):
        return "Waktu tunggu koneksi Odoo habis."
    if isinstance(error, ConnectionRefusedError):
        return "Koneksi ditolak oleh server Odoo."
    if isinstance(error, (Fault, ProtocolError)):
        return "Server dapat dijangkau, tetapi respons XML-RPC Odoo tidak valid."
    if isinstance(error, OSError):
        return "Server Odoo tidak dapat dijangkau. Periksa URL, DNS, dan jaringan."
    return "Pemeriksaan koneksi Odoo gagal. Periksa konfigurasi URL server."


def require_school_admin(
    session_token: str | None = Cookie(default=None, alias=SESSION_COOKIE),
    db: Session = Depends(get_db),
) -> str:
    if not session_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Silakan masuk sebagai admin terlebih dahulu.",
        )
    try:
        payload = jwt.decode(
            session_token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
        )
    except PyJWTError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sesi admin tidak valid atau sudah kedaluwarsa.",
        ) from exc

    if payload.get("purpose") != "school_admin" or not payload.get("sub"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sesi admin tidak valid.",
        )
    username = normalize_username(payload["sub"])
    account = (
        db.query(SchoolAdminAccount)
        .filter(SchoolAdminAccount.username == username)
        .first()
    )
    if not account or not account.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Akun admin tidak aktif atau tidak ditemukan.",
        )
    return account.username


def _school_data(school: SchoolTenant) -> dict:
    return {
        "id": school.id,
        "school_code": school.school_code,
        "school_name": school.school_name,
        "odoo_url": school.odoo_url,
        "odoo_db": school.odoo_db,
        "is_active": school.is_active,
    }


def _commit_school(db: Session) -> None:
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Kode sekolah sudah digunakan.",
        ) from exc


@router.post("/session")
def create_admin_session(
    payload: AdminLoginRequest,
    response: Response,
    db: Session = Depends(get_db),
):
    if not db.query(SchoolAdminAccount).first():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Akun admin belum tersedia. Konfigurasikan akun bootstrap lalu mulai ulang backend.",
        )

    username = normalize_username(payload.username)
    account = (
        db.query(SchoolAdminAccount)
        .filter(SchoolAdminAccount.username == username)
        .first()
    )
    password_matches = verify_password(
        payload.password,
        account.password_hash if account else _DUMMY_PASSWORD_HASH,
    )
    if not account or not account.is_active or not password_matches:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Username atau password admin salah.",
        )

    now = datetime.now(timezone.utc)
    token = jwt.encode(
        {
            "sub": account.username,
            "purpose": "school_admin",
            "iat": now,
            "exp": now + SESSION_DURATION,
        },
        settings.JWT_SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM,
    )
    response.set_cookie(
        key=SESSION_COOKIE,
        value=token,
        httponly=True,
        secure=settings.APP_ENV.lower() == "production",
        samesite="strict",
        max_age=int(SESSION_DURATION.total_seconds()),
        path="/api/v1/admin",
    )
    return {"success": True, "data": {"username": account.username}}


@router.delete("/session")
def delete_admin_session(response: Response):
    response.delete_cookie(
        key=SESSION_COOKIE,
        httponly=True,
        secure=settings.APP_ENV.lower() == "production",
        samesite="strict",
        path="/api/v1/admin",
    )
    return {"success": True}


@router.get("/session")
def get_admin_session(username: str = Depends(require_school_admin)):
    return {"success": True, "data": {"username": username}}


@router.get("/schools")
def list_admin_schools(
    _: str = Depends(require_school_admin),
    db: Session = Depends(get_db),
):
    schools = db.query(SchoolTenant).order_by(SchoolTenant.school_name).all()
    return {"success": True, "data": [_school_data(school) for school in schools]}


@router.post("/schools/connections/check")
def check_school_connections(
    _: str = Depends(require_school_admin),
    db: Session = Depends(get_db),
):
    schools = db.query(SchoolTenant).order_by(SchoolTenant.school_name).all()
    with ThreadPoolExecutor(max_workers=ODOO_PROBE_WORKERS) as executor:
        results = list(executor.map(_check_odoo_connection, schools))
    return {"success": True, "data": results}


@router.post("/schools/{school_id}/connection/check")
def check_school_connection(
    school_id: int,
    _: str = Depends(require_school_admin),
    db: Session = Depends(get_db),
):
    school = db.query(SchoolTenant).filter(SchoolTenant.id == school_id).first()
    if not school:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sekolah tidak ditemukan.",
        )
    return {"success": True, "data": _check_odoo_connection(school)}


@router.post("/schools", status_code=status.HTTP_201_CREATED)
def create_school(
    payload: SchoolCreate,
    _: str = Depends(require_school_admin),
    db: Session = Depends(get_db),
):
    school = SchoolTenant(**payload.model_dump())
    db.add(school)
    _commit_school(db)
    db.refresh(school)
    return {"success": True, "data": _school_data(school)}


@router.patch("/schools/{school_id}")
def update_school(
    school_id: int,
    payload: SchoolUpdate,
    _: str = Depends(require_school_admin),
    db: Session = Depends(get_db),
):
    updates = payload.model_dump(exclude_unset=True)
    if not updates:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Tidak ada perubahan yang dikirim.",
        )

    school = db.query(SchoolTenant).filter(SchoolTenant.id == school_id).first()
    if not school:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sekolah tidak ditemukan.",
        )

    for field, value in updates.items():
        setattr(school, field, value)
    _commit_school(db)
    db.refresh(school)
    return {"success": True, "data": _school_data(school)}
