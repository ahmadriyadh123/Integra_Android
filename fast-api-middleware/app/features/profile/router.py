import base64

from fastapi import APIRouter, Depends, HTTPException, Response, status
from app.core.dependencies import get_odoo_client, get_current_user_credentials
from app.features.profile.schemas import APIResponseProfile
from app.features.profile.repository import ProfileRepository
from app.features.profile.service import ProfileService

router = APIRouter(
    prefix="/profile",
    tags=["Menu Profil Siswa"]
)

@router.get("/image/{partner_id}")
@router.get("/partner/{partner_id}/image")
def get_profile_image(
    partner_id: int,
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client),
):
    try:
        repo = ProfileRepository(odoo_client)
        allowed_partner_id = creds.get("partner_id")
        if not allowed_partner_id:
            student = repo.get_student_profile_record(
                uid=creds["uid"],
                password=creds["password"],
                student_id=creds.get("student_id"),
            )
            student_partner = student.get("partner_id") if student else None
            allowed_partner_id = (
                student_partner[0]
                if isinstance(student_partner, (list, tuple)) and student_partner
                else student_partner if isinstance(student_partner, int) else None
            )

        if allowed_partner_id != partner_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Akses foto profil ditolak")

        image = repo.get_partner_image(
            uid=creds["uid"],
            password=creds["password"],
            partner_id=partner_id,
        )
        raw_data = image.get("image_1920") if image else None
        if not raw_data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Foto profil tidak ditemukan")

        if isinstance(raw_data, str):
            image_bytes = base64.b64decode(raw_data, validate=True)
        elif isinstance(raw_data, bytes):
            image_bytes = base64.b64decode(raw_data, validate=True)
        else:
            raise ValueError("Format image_1920 tidak dikenali")

        return Response(
            content=image_bytes,
            media_type="image/jpeg",
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil foto profil: {str(e)}",
        )

@router.get("/me", response_model=APIResponseProfile)
def get_my_profile(
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    user_id = creds.get("uid")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sesi pengguna tidak valid. Silakan login kembali."
        )
    try:
        repo = ProfileRepository(odoo_client)
        service = ProfileService(repo)

        data = service.get_student_profile(
            uid=user_id,
            password=creds["password"],
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
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil profil siswa dari Odoo: {str(e)}"
        )