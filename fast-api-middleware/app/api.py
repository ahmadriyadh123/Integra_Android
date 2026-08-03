# app/api.py
from fastapi import APIRouter

# Import router dari tiap modul fitur
from app.features.auth.router import router as auth_router
from app.features.profile.router import router as profile_router
from app.features.tagihan.router import router as tagihan_router
from app.features.attendance.router import router as attendance_router
from app.features.elearning.router import router as elearning_router
from app.features.calendar.router import router as calendar_router
from app.features.weekly_plan.router import router as weekly_plan_router
from app.features.buku_komunikasi.router import router as buku_komunikasi_router
from app.features.cbt.router import router as cbt_router

# Router utama untuk seluruh v1 API
api_router = APIRouter(prefix="/api/v1")

# Gabungkan router masing-masing fitur ke router utama
api_router.include_router(auth_router)
api_router.include_router(profile_router)
api_router.include_router(tagihan_router)
api_router.include_router(attendance_router)
api_router.include_router(elearning_router)
api_router.include_router(calendar_router)
api_router.include_router(weekly_plan_router)
api_router.include_router(buku_komunikasi_router)
api_router.include_router(cbt_router)