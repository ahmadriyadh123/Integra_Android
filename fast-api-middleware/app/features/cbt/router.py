from fastapi import APIRouter, Depends, HTTPException, status
from app.core.dependencies import get_odoo_client, get_current_user_credentials
from app.features.cbt.schemas import (
    APIResponseCbtList,
    VerifyTokenRequest,
    APIResponseCbtQuestions
)
from app.features.cbt.repository import CbtRepository
from app.features.cbt.service import CbtService

router = APIRouter(
    prefix="/cbt",
    tags=["Menu Ujian CBT"]
)

@router.get("/schedules", response_model=APIResponseCbtList)
def get_cbt_schedules(
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    try:
        repo = CbtRepository(odoo_client)
        service = CbtService(repo)

        data = service.get_exam_list(uid=creds["uid"], password=creds["password"])

        return APIResponseCbtList(
            success=True,
            message="Berhasil mengambil jadwal ujian CBT",
            data=data
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil jadwal CBT dari Odoo: {str(e)}"
        )

@router.post("/verify-token")
def verify_exam_token(
    payload: VerifyTokenRequest,
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    try:
        repo = CbtRepository(odoo_client)
        service = CbtService(repo)

        is_valid = service.verify_token(
            uid=creds["uid"],
            password=creds["password"],
            jadwal_id=payload.jadwal_ujian_id,
            token_input=payload.token_input
        )

        if not is_valid:
            return {
                "success": False,
                "message": "Token ujian tidak valid. Periksa kembali token dari panitia.",
                "data": False
            }

        return {
            "success": True,
            "message": "Token ujian valid! Memulai ujian...",
            "data": True
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal melakukan verifikasi token: {str(e)}"
        )

@router.get("/questions/{jadwal_id}", response_model=APIResponseCbtQuestions)
def get_exam_questions(
    jadwal_id: int,
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    try:
        repo = CbtRepository(odoo_client)
        service = CbtService(repo)

        data = service.get_exam_questions(
            uid=creds["uid"],
            password=creds["password"],
            jadwal_id=jadwal_id
        )

        return APIResponseCbtQuestions(
            success=True,
            message="Berhasil mengambil soal ujian CBT",
            data=data
        )
    except ValueError as ve:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(ve)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil soal ujian dari Odoo: {str(e)}"
        )