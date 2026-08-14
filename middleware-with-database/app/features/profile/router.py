# app/features/profile/router.py
import logging
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db, get_current_user_credentials
from app.features.profile.schemas import APIResponseProfile
from app.features.profile.repository import ProfileRepository
from app.features.profile.service import ProfileService

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/profile",
    tags=["Menu Profil Siswa"]
)

@router.get("/me", response_model=APIResponseProfile)
async def get_my_profile(
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db)
):
    user_id = creds.get("uid")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sesi pengguna tidak valid. Silakan login kembali."
        )

    try:
        repo = ProfileRepository(db)
        service = ProfileService(repo)
        data = await service.get_student_profile(user_id=user_id)

        if not data:
            return APIResponseProfile(
                success=False,
                message="Data profil siswa tidak ditemukan di sistem",
                data=None
            )

        return APIResponseProfile(
            success=True,
            message="Berhasil mengambil profil siswa",
            data=data
        )
    except Exception as e:
        logger.error(f"[profile/me] Error uid={user_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil profil siswa: {str(e)}"
        )