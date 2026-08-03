from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import api_router

app = FastAPI(
    title="Odoo Mobile Middleware API",
    version="1.0.0",
    description="Middleware REST API untuk menghubungkan Flutter Mobile dengan Database PostgreSQL Odoo"
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
def root():
    return {"status": "Active", "message": "Odoo Mobile Middleware Services Running"}