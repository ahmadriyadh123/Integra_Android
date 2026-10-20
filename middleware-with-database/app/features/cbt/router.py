from datetime import datetime, timedelta, timezone
import logging

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db, get_current_user_credentials
from app.features.cbt.schemas import (
    APIResponseCbtList,
    APIResponseCbtSync,
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
async def get_cbt_schedules(
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db)
):
    """Daftar jadwal ujian CBT untuk kelas user yang login."""
    try:
        repo = CbtRepository(db)
        service = CbtService(repo)
        data = await service.get_exam_list(
            course_id=creds.get("course_id"),
            student_id=creds.get("student_id")
        )
        return APIResponseCbtList(
            success=True,
            message="Berhasil mengambil jadwal ujian CBT",
            data=data
        )
    except Exception as e:
        logger.exception("[cbt/schedules] Error uid=%s", creds.get("uid"))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Jadwal ujian belum dapat dimuat. Silakan coba lagi.",
        ) from e


@router.get("/schedules/sync", response_model=APIResponseCbtSync)
async def sync_cbt_schedules(
    cursor: str | None = None,
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db),
):
    try:
        service = CbtService(CbtRepository(db))
        parsed_cursor = datetime.fromisoformat(cursor.replace("Z", "+00:00")) if cursor else None
        if parsed_cursor is not None and parsed_cursor.tzinfo is None:
            parsed_cursor = parsed_cursor.replace(tzinfo=timezone.utc)
        schedule_list = await service.get_exam_list(
            course_id=creds.get("course_id"),
            student_id=creds.get("student_id"),
            changed_since=parsed_cursor - timedelta(seconds=2) if parsed_cursor else None,
        )
        return {
            "success": True,
            "message": "Berhasil menyinkronkan jadwal ujian CBT",
            "data": {
                "exams": schedule_list["exams"],
                "removed_ids": [],
                "cursor": datetime.now(timezone.utc).isoformat(),
                "is_full_sync": parsed_cursor is None,
            },
        }
    except Exception as exc:
        logger.exception("[cbt/schedules/sync] Error uid=%s", creds.get("uid"))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Gagal menyinkronkan jadwal CBT.",
        ) from exc


@router.post("/verify-token")
async def verify_exam_token(
    payload: VerifyTokenRequest,
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db)
):
    """Verifikasi token ujian sebelum mengerjakan soal."""
    try:
        repo = CbtRepository(db)
        service = CbtService(repo)
        is_valid = await service.verify_token(
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
        logger.exception("[cbt/verify-token] Error uid=%s", creds.get("uid"))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Token ujian belum dapat diperiksa. Silakan coba lagi.",
        ) from e

@router.get("/questions/{jadwal_id}", response_model=APIResponseCbtQuestions)
async def get_exam_questions(
    jadwal_id: int,
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db)
):
    """Ambil soal ujian berdasarkan jadwal ID."""
    try:
        repo = CbtRepository(db)
        service = CbtService(repo)
        data = await service.get_exam_questions(jadwal_id=jadwal_id)
        return APIResponseCbtQuestions(
            success=True,
            message="Berhasil mengambil soal ujian",
            data=data
        )
    except ValueError as ve:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(ve))
    except Exception as e:
        logger.exception(
            "[cbt/questions/%s] Error uid=%s",
            jadwal_id,
            creds.get("uid"),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Soal ujian belum dapat dimuat. Silakan coba lagi.",
        ) from e

@router.post("/submit", response_model=APIResponseSubmitExam)
async def submit_exam(
    payload: SubmitExamPayload,
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db)
):
    """Submit jawaban ujian setelah selesai mengerjakan."""
    student_id = creds.get("student_id")
    course_id = creds.get("course_id")
    if not student_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Data siswa tidak ditemukan. Silakan login ulang."
        )
    try:
        repo = CbtRepository(db)
        service = CbtService(repo)
        data = await service.submit_exam(
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
        logger.exception("[cbt/submit] Error uid=%s", creds.get("uid"))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Jawaban ujian belum dapat dikirim. Silakan coba lagi.",
        ) from e

@router.get("/riwayat", response_model=APIResponseRiwayatUjian)
async def get_riwayat_ujian(
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db)
):
    """Riwayat hasil ujian siswa yang login."""
    student_id = creds.get("student_id")
    if not student_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Data siswa tidak ditemukan. Silakan login ulang."
        )
    try:
        repo = CbtRepository(db)
        service = CbtService(repo)
        data = await service.get_riwayat_ujian(student_id=student_id)
        return APIResponseRiwayatUjian(
            success=True,
            message="Berhasil mengambil riwayat ujian",
            data=data
        )
    except Exception as e:
        logger.exception("[cbt/riwayat] Error uid=%s", creds.get("uid"))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Riwayat ujian belum dapat dimuat. Silakan coba lagi.",
        ) from e
