# app/features/auth/router.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
import logging
from typing import Dict, Any

from app.core.dependencies import get_db, get_current_user_credentials
from app.features.auth.schemas import LoginRequest, APIResponseLogin, TokenResponse, UserProfileData
from app.features.auth.schemas import LoginRequest, ChangePasswordRequest, APIResponseLogin, TokenResponse, UserProfileData
from app.features.auth.repository import AuthRepository
from app.features.auth.service import AuthService

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/auth",
    tags=["Autentikasi & Login"]
)

@router.post("/login", response_model=APIResponseLogin)
async def login(
    payload: LoginRequest,
    db: AsyncSession = Depends(get_db)
):
    repo = AuthRepository(db)

    # 1. Cek apakah user/email ada di database
    user_exists = await repo.get_user_by_login(payload.username)
    
    if not user_exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Email/Username tidak ditemukan. Silakan periksa kembali.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # 2. Verifikasi Kredensial via Query Database
    user_info = await repo.authenticate_user(
        login=payload.username, 
        password_plain=payload.password
    )

    if not user_info:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Password salah. Silakan periksa kembali.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # 3. Buat Payload JWT (Bebas dari password mentah)
    jwt_payload = {
        "uid": user_info["user_id"],
        "sub": str(user_info["user_id"]),
        "username": user_info["login"],
        "partner_id": user_info["partner_id"],
        "course_id": user_info.get("course_id"),
        "student_id": user_info["student_id"],
        "jenjang": user_info.get("jenjang", "sd"),
        "is_portal": user_info["is_portal"]
    }

    access_token = AuthService.create_access_token(data=jwt_payload)

    # 4. Buat Response
    response_data = TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user=UserProfileData(
            user_id=user_info["user_id"],
            partner_id=user_info["partner_id"],
            student_id=user_info["student_id"],
            nis=user_info["nis"],
            name=user_info["name"],
            username=user_info["login"],
            email=user_info["email"],
            is_portal=user_info["is_portal"]
        )
    )

    return APIResponseLogin(
        success=True,
        message="Login berhasil",
        data=response_data
    )


@router.post("/validate")
async def validate_token(
    creds: Dict[str, Any] = Depends(get_current_user_credentials),
):
    """
    Validasi token JWT tanpa database query.
    Endpoint ini digunakan Flutter app untuk background session validation.
    Jika token valid (signature & expiration OK), return success.
    Jika token invalid/expired, dependency akan throw 401.
    """
    return {
        "success": True,
        "message": "Token valid",
        "data": {
            "user_id": creds.get("uid"),
            "username": creds.get("username"),
        }
    }

@router.post("/change-password")
async def change_password(
    payload: ChangePasswordRequest,
    creds: Dict[str, Any] = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db),
):
    if len(payload.new_password) < 6:
        raise HTTPException(status_code=400, detail="Password baru minimal 6 karakter.")
    if payload.current_password == payload.new_password:
        raise HTTPException(status_code=400, detail="Password baru harus berbeda dari password lama.")

    repo = AuthRepository(db)
    updated = await repo.change_password(
        user_id=creds["uid"],
        current_password=payload.current_password,
        new_password=payload.new_password,
    )
    if not updated:
        raise HTTPException(status_code=401, detail="Password lama tidak sesuai.")
    return {"success": True, "message": "Password berhasil diperbarui."}