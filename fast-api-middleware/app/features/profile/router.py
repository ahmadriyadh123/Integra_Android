from fastapi import APIRouter, Depends, HTTPException, status
from app.core.dependencies import get_odoo_client, get_current_user_credentials
from app.features.profile.schemas import APIResponseProfile
from app.features.profile.repository import ProfileRepository
from app.features.profile.service import ProfileService

router = APIRouter(
    prefix="/profile",
    tags=["Menu Profil Siswa"]
)

@router.get("/me", response_model=APIResponseProfile)
def get_my_profile(
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    try:
        repo = ProfileRepository(odoo_client)
        service = ProfileService(repo)

        data = service.get_student_profile(
            uid=creds["uid"],
            password=creds["password"]
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