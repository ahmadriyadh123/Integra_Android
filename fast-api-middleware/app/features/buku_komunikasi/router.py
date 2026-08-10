from fastapi import APIRouter, Depends, HTTPException, status
from app.core.dependencies import get_odoo_client, get_current_user_credentials
from app.features.buku_komunikasi.service import BukuKomunikasiService
from app.features.buku_komunikasi.repository import BukuKomunikasiRepository
from app.features.buku_komunikasi.schemas import APIResponseBukuKomunikasi, UpdateFeedbackRequest

router = APIRouter(
    prefix="/buku-komunikasi",
    tags=["Menu Buku Komunikasi"]
)

@router.get("", response_model=APIResponseBukuKomunikasi)
def get_buku_komunikasi(
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    try:
        repo = BukuKomunikasiRepository(odoo_client)
        service = BukuKomunikasiService(repo)

        data = service.get_buku_komunikasi(
            uid=creds['uid'],
            password=creds['password'],
            student_id=creds.get('student_id'),
            jenjang=creds.get('jenjang', 'sd')
        )

        if not data:
            return APIResponseBukuKomunikasi(
                success=True,
                message ="Data buku komunikasi tidak ditemukan untuk siswa ini",
                data=None
            )
        
        return APIResponseBukuKomunikasi(
            success=True,
            message="Berhasil mengambil data buku komunikasi",
            data=data
        )
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil buku komunikasi: {str(e)}"
        )

@router.post("/feedback")
def submit_parent_feedback(
    payload: UpdateFeedbackRequest, 
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    try:
        repo = BukuKomunikasiRepository(odoo_client)
        service = BukuKomunikasiService(repo)
        
        success = service.save_feedback(
            uid=creds['uid'],
            password=creds['password'],
            line_id=payload.line_id, 
            day=payload.day, 
            feedback_text=payload.feedback_text,
            jenjang=creds.get('jenjang', 'sd')
        )

        if success:
            return {"success": True, "message": "Feedback orang tua berhasil disimpan"}
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Gagal menyimpan feedback. Periksa kembali data yang dikirim."
            )
    except ValueError as ve:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(ve)
        )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal menyimpan feedback: {str(e)}"
        )