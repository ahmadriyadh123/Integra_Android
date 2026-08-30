import logging
import base64

from fastapi import APIRouter, Depends, HTTPException, Response, status
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


@router.get("/image/{partner_id}")
@router.get("/partner/{partner_id}/image")
async def get_partner_image(
    partner_id: int,
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db),
):
    """Mengirim foto partner login dari ir_attachment sebagai binary image."""
    if creds.get("partner_id") != partner_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Anda tidak memiliki akses ke foto profil ini.",
        )

    record = await ProfileRepository(db).get_partner_image(partner_id)
    if not record:
        return Response(status_code=status.HTTP_404_NOT_FOUND)

    raw_data = record.get("db_datas")
    try:
        if isinstance(raw_data, memoryview):
            raw_data = raw_data.tobytes()
        if isinstance(raw_data, str):
            image_bytes = base64.b64decode(raw_data, validate=True)
        elif isinstance(raw_data, bytes):
            try:
                image_bytes = base64.b64decode(raw_data, validate=True)
            except ValueError:
                image_bytes = raw_data
        else:
            raise TypeError("Data foto tidak dikenali")
    except (TypeError, ValueError):
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Format foto profil tidak valid.",
        )

    media_type = record.get("mimetype") or "application/octet-stream"
    return Response(content=image_bytes, media_type=media_type)

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
        data = await service.get_student_profile(
            user_id=user_id,
            partner_id=creds.get("partner_id"),
            student_id=creds.get("student_id"),
        )

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