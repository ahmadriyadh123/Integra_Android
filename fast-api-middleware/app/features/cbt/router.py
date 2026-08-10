import logging
from fastapi import APIRouter, Depends, HTTPException, status
from app.core.dependencies import get_odoo_client, get_current_user_credentials
from app.features.cbt.schemas import (
    APIResponseCbtList,
    VerifyTokenRequest,
    APIResponseCbtQuestions,
    SubmitExamPayload,
    APIResponseSubmitExam,
    APIResponseRiwayatUjian,
)
from app.features.cbt.repository import CbtRepository
from app.features.cbt.service import CbtService

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/cbt",
    tags=["Menu Ujian CBT"]
)


@router.get("/schedules", response_model=APIResponseCbtList)
def get_cbt_schedules(
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    """Daftar jadwal ujian CBT untuk kelas user yang login."""
    try:
        repo = CbtRepository(odoo_client)
        service = CbtService(repo)

        data = service.get_exam_list(
            uid=creds["uid"],
            password=creds["password"],
            course_id=creds.get("course_id")
        )
        return APIResponseCbtList(
            success=True,
            message="Berhasil mengambil jadwal ujian CBT",
            data=data
        )
    except Exception as e:
        logger.error(f"[cbt/schedules] Error uid={creds['uid']}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil jadwal CBT: {str(e)}"
        )


@router.post("/verify-token")
def verify_exam_token(
    payload: VerifyTokenRequest,
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    """Verifikasi token ujian sebelum mengerjakan soal."""
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
                "message": "Token ujian tidak valid. Periksa kembali token dari pengawas.",
                "data": False
            }
        return {
            "success": True,
            "message": "Token valid! Ujian dapat dimulai.",
            "data": True
        }
    except Exception as e:
        logger.error(f"[cbt/verify-token] Error uid={creds['uid']}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal verifikasi token: {str(e)}"
        )


@router.get("/questions/{jadwal_id}", response_model=APIResponseCbtQuestions)
def get_exam_questions(
    jadwal_id: int,
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    """Ambil soal ujian berdasarkan jadwal ID."""
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
            message="Berhasil mengambil soal ujian",
            data=data
        )
    except ValueError as ve:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(ve))
    except Exception as e:
        logger.error(f"[cbt/questions/{jadwal_id}] Error uid={creds['uid']}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil soal ujian: {str(e)}"
        )


@router.post("/submit", response_model=APIResponseSubmitExam)
def submit_exam(
    payload: SubmitExamPayload,
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    """Submit jawaban ujian setelah selesai mengerjakan."""
    student_id = creds.get("student_id")
    course_id  = creds.get("course_id")

    if not student_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Data siswa tidak ditemukan. Silakan login ulang."
        )

    try:
        repo = CbtRepository(odoo_client)
        service = CbtService(repo)

        data = service.submit_exam(
            uid=creds["uid"],
            password=creds["password"],
            student_id=student_id,
            course_id=course_id or 0,
            jadwal_id=payload.jadwal_ujian_id,
            answers=[a.model_dump() for a in payload.answers],
            waktu_mulai=payload.waktu_mulai
        )
        return APIResponseSubmitExam(
            success=True,
            message="Ujian berhasil diselesaikan.",
            data=data
        )
    except ValueError as ve:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(ve))
    except Exception as e:
        logger.error(f"[cbt/submit] Error uid={creds['uid']}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal menyimpan jawaban ujian: {str(e)}"
        )


@router.get("/riwayat", response_model=APIResponseRiwayatUjian)
def get_riwayat_ujian(
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    """Riwayat hasil ujian siswa yang login."""
    student_id = creds.get("student_id")
    if not student_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Data siswa tidak ditemukan. Silakan login ulang."
        )

    try:
        repo = CbtRepository(odoo_client)
        service = CbtService(repo)

        data = service.get_riwayat_ujian(
            uid=creds["uid"],
            password=creds["password"],
            student_id=student_id
        )
        return APIResponseRiwayatUjian(
            success=True,
            message="Berhasil mengambil riwayat ujian",
            data=data
        )
    except Exception as e:
        logger.error(f"[cbt/riwayat] Error uid={creds['uid']}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil riwayat ujian: {str(e)}"
        )
