from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import api_router
from app.core.database import dispose_database_engines, registry_engine
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

@app.get("/")
async def root():
    return {"status": "Active", "message": "Odoo Mobile Middleware Services Running"}