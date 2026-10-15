from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select
from sqlalchemy.exc import SQLAlchemyError

from app.api import api_router
from app.core.config import settings
from app.core.database import (
    RegistrySessionLocal,
    dispose_database_engines,
    registry_engine,
)
from app.core.models import SchoolTenant

@asynccontextmanager
async def lifespan(app: FastAPI):
    async with registry_engine.begin() as connection:
        await connection.run_sync(SchoolTenant.metadata.create_all)
    try:
        yield
    finally:
        await dispose_database_engines()

app = FastAPI(
    title="Odoo Mobile Middleware API",
    version="1.0.0",
    description="Middleware REST API untuk menghubungkan Flutter Mobile dengan Database PostgreSQL Odoo",
    lifespan=lifespan
)

# Konfigurasi CORS agar Flutter Web/Device dapat mengakses API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],    
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)

@app.get("/client-config", include_in_schema=False)
async def client_config():
    return {"api_base_url": settings.CLIENT_API_BASE_URL}

@app.get("/")
async def root():
    return {"status": "Active", "message": "Odoo Mobile Middleware Services Running"}


@app.get("/health/live")
async def liveness():
    return {"status": "ok"}


@app.get("/health/ready")
async def readiness():
    try:
        async with RegistrySessionLocal() as session:
            result = await session.execute(
                select(SchoolTenant.id).where(SchoolTenant.is_active.is_(True))
            )
            active_school_count = len(result.scalars().all())
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