from fastapi import APIRouter, Depends, HTTPException, status
from app.core.dependencies import get_odoo_client, get_current_user_credentials
from app.features.buku_komunikasi.service import BukuKomunikasiService
from app.features.buku_komunikasi.repository import BukuKomunikasiRepository
from app.features.buku_komunikasi.schemas import APIResponseBukuKomunikasi, UpdateNoteRequest, UpdateFeedbackRequest
from app.features.auth.repository import AuthRepository

router = APIRouter(
    prefix="/buku-komunikasi",
    tags=["Menu Buku Komunikasi"]
)


def _resolve_student_id(creds: dict, odoo_client) -> int:
    student_id = creds.get('student_id')
    if isinstance(student_id, int) and student_id > 0:
        return student_id

    student_id, _, _, _ = AuthRepository(odoo_client).resolve_student_context(
        uid=creds['uid'],
        password=creds['password'],
        partner_id=creds.get('partner_id'),
    )
    if not student_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                "Data siswa belum terhubung dengan akun Odoo Anda. "
                "Pastikan relasi user/partner ke siswa sudah diatur."
            ),
        )
    return student_id


@router.get("", response_model=APIResponseBukuKomunikasi)
def get_buku_komunikasi(
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    try:
        student_id = _resolve_student_id(creds, odoo_client)
        repo = BukuKomunikasiRepository(odoo_client)
        service = BukuKomunikasiService(repo)

        data = service.get_buku_komunikasi(
            uid=creds['uid'],
            password=creds['password'],
            student_id=student_id,
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
    
    except HTTPException:
        raise
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
    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal menyimpan feedback: {str(e)}"
        )

@router.post("/note")
def submit_daily_note(
    payload: UpdateNoteRequest, 
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    try:
        repo = BukuKomunikasiRepository(odoo_client)
        service = BukuKomunikasiService(repo)
        student_id = _resolve_student_id(creds, odoo_client)
        
        success = service.save_daily_note(
            uid=creds['uid'],
            password=creds['password'],
            student_id=student_id,
            line_id=payload.line_id, 
            day=payload.day, 
            note_text=payload.note_text,
            month=payload.month,
            week=payload.week,
            jenjang=creds.get('jenjang', 'sd')
        )
        if success:
            return {"success": True, "message": "Catatan harian berhasil disimpan"}
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Gagal menyimpan catatan. Periksa kembali data yang dikirim."
            )
    except ValueError as ve:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(ve)
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal menyimpan catatan: {str(e)}"
        )