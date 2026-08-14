# app/features/auth/router.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
import logging

from app.core.dependencies import get_db
from app.features.auth.schemas import LoginRequest, APIResponseLogin, TokenResponse, UserProfileData
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

    # 1. Verifikasi Kredensial via Query Database
    user_info = await repo.authenticate_user(
        login=payload.username, 
        password_plain=payload.password
    )

    if not user_info:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Username/Email atau Password salah. Silakan periksa kembali kredensial Anda.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # 2. Buat Payload JWT (Bebas dari password mentah)
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

    # 3. Buat Response
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