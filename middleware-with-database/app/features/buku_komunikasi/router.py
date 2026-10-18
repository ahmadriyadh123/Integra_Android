import logging
from typing import Any, Dict, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user_credentials, get_db
from app.features.buku_komunikasi.repository import BukuKomunikasiRepository
from app.features.buku_komunikasi.schemas import (
    APIResponseBukuKomunikasi,
    APIResponseBukuKomunikasiSync,
    UpdateFeedbackRequest,
    UpdateNoteRequest,
)
from app.features.buku_komunikasi.service import BukuKomunikasiService

router = APIRouter(
    prefix="/buku-komunikasi",
    tags=["Menu Buku Komunikasi"],
)
logger = logging.getLogger(__name__)


def _student_id(credentials: Dict[str, Any]) -> int:
    student_id = credentials.get("student_id")
    if type(student_id) is not int or student_id <= 0:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Data siswa tidak ditemukan dalam sesi Anda.",
        )
    return student_id


def _service(db: AsyncSession) -> BukuKomunikasiService:
    return BukuKomunikasiService(BukuKomunikasiRepository(db))


@router.get("", response_model=APIResponseBukuKomunikasi)
async def get_buku_komunikasi(
    creds: Dict[str, Any] = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db),
):
    student_id = _student_id(creds)
    try:
        data = await _service(db).get_buku_komunikasi(
            student_id=student_id,
            jenjang=creds.get("jenjang", "sd"),
        )
        if not data:
            return APIResponseBukuKomunikasi(
                success=True,
                message="Data buku komunikasi tidak ditemukan untuk siswa ini",
                data=None,
            )
        return APIResponseBukuKomunikasi(
            success=True,
            message="Berhasil mengambil data buku komunikasi",
            data=data,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc
    except Exception as exc:
        logger.exception(
            "[buku-komunikasi] Gagal mengambil data uid=%s",
            creds.get("uid"),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Gagal mengambil buku komunikasi.",
        ) from exc


@router.get("/sync", response_model=APIResponseBukuKomunikasiSync)
async def sync_buku_komunikasi(
    cursor: Optional[str] = Query(
        None,
        description="Timestamp ISO terakhir sync. Null = full sync.",
    ),
    creds: Dict[str, Any] = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db),
):
    """
    Delta sync buku komunikasi.
    - cursor=null  → full sync, kembalikan semua line
    - cursor=<iso> → delta sync, kembalikan hanya line yang write_date >= cursor
                     beserta all_active_ids agar client bisa deteksi removed
    """
    student_id = _student_id(creds)
    try:
        data = await _service(db).sync_buku_komunikasi(
            student_id=student_id,
            jenjang=creds.get("jenjang", "sd"),
            cursor=cursor,
        )
        if not data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Data buku komunikasi tidak ditemukan untuk siswa ini.",
            )
        return APIResponseBukuKomunikasiSync(
            success=True,
            message="Berhasil sinkronisasi buku komunikasi",
            data=data,
        )
    except HTTPException:
        raise
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)
        ) from exc
    except Exception as exc:
        logger.exception(
            "[buku-komunikasi/sync] Gagal sync uid=%s", creds.get("uid")
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Gagal sinkronisasi buku komunikasi.",
        ) from exc


@router.post("/note")
async def submit_daily_note(
    payload: UpdateNoteRequest,
    creds: Dict[str, Any] = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db),
):
    student_id = _student_id(creds)
    try:
        success = await _service(db).save_daily_note(
            student_id=student_id,
            line_id=payload.line_id,
            day=payload.day,
            note_text=payload.note_text,
            month=payload.month,
            week=payload.week,
            jenjang=creds.get("jenjang", "sd"),
        )
        if success:
            return {
                "success": True,
                "message": "Catatan harian berhasil disimpan",
            }
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Gagal menyimpan catatan. Periksa kembali data yang dikirim.",
        )
    except ValueError as exc:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(exc),
        ) from exc
    except HTTPException:
        await db.rollback()
        raise
    except Exception as exc:
        await db.rollback()
        logger.exception(
            "[buku-komunikasi/note] Gagal menyimpan catatan uid=%s",
            creds.get("uid"),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Gagal menyimpan catatan.",
        ) from exc


@router.post("/feedback")
async def submit_parent_feedback(
    payload: UpdateFeedbackRequest,
    creds: Dict[str, Any] = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db),
):
    student_id = _student_id(creds)
    try:
        success = await _service(db).save_parent_feedback(
            student_id=student_id,
            line_id=payload.line_id,
            day=payload.day,
            feedback_text=payload.feedback_text,
            jenjang=creds.get("jenjang", "sd"),
        )
        if success:
            return {
                "success": True,
                "message": "Feedback orang tua berhasil disimpan",
            }
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Gagal menyimpan feedback. Periksa kembali data yang dikirim.",
        )
    except ValueError as exc:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(exc),
        ) from exc
    except HTTPException:
        await db.rollback()
        raise
    except Exception as exc:
        await db.rollback()
        logger.exception(
            "[buku-komunikasi/feedback] Gagal menyimpan feedback uid=%s",
            creds.get("uid"),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Gagal menyimpan feedback.",
        ) from exc
