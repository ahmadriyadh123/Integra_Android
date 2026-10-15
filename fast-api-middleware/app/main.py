from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.exc import SQLAlchemyError

from app.api import api_router
from app.core.config import settings
from app.core.database import SessionLocal
from app.core.models import SchoolTenant

app = FastAPI(
    title="Odoo Mobile Middleware API",
    version="1.0.0",
    description="Middleware REST API untuk menghubungkan Flutter Mobile dengan Odoo RPC"
)

# Konfigurasi CORS agar Flutter Web/Device dapat mengakses API
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=bool(settings.cors_origins),
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)

@app.get("/")
async def root():
    return {"status": "Active", "message": "Odoo Mobile Middleware Services Running"}


@app.get("/health/live")
async def liveness():
    return {"status": "ok"}


@app.get("/health/ready")
def readiness():
    try:
        with SessionLocal() as db:
            active_school_count = (
                db.query(SchoolTenant)
                .filter(SchoolTenant.is_active.is_(True))
                .count()
            )
    except SQLAlchemyError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"status": "not_ready", "registry": "unreachable"},
        ) from exc

    if active_school_count == 0:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"status": "not_ready", "reason": "no_active_tenants"},
        )
    return {"status": "ready", "configured_schools": active_school_count}