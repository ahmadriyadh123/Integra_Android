import socket

from fastapi import FastAPI
from fastapi import HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from app.api import api_router
from app.core.config import settings

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
async def readiness():
    try:
        with socket.create_connection((settings.ODOO_HOST, settings.ODOO_PORT), timeout=2):
            return {"status": "ready", "odoo": "reachable"}
    except OSError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"status": "not_ready", "odoo": "unreachable"},
        ) from exc