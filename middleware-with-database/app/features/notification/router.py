"""Endpoint polling notifikasi berdasarkan perubahan data di tabel fitur.

GET /notifications?cursor=<ISO timestamp>
  - Mengembalikan daftar notifikasi baru sejak cursor
  - Jika cursor null, cek 30 hari terakhir (full sync)
"""

import logging
from typing import Any, Dict, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user_credentials, get_db
from app.features.notification.repository import NotificationRepository

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/notifications",
    tags=["Notifikasi"],
)


@router.get("")
async def get_notifications(
    cursor: Optional[str] = Query(None),
    creds: Dict[str, Any] = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db),
):
    student_id = creds.get("student_id")
    if not isinstance(student_id, int) or student_id <= 0:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Data siswa tidak ditemukan dalam sesi Anda.",
        )

    repo = NotificationRepository(db)
    try:
        result = await repo.get_notifications(
            student_id=student_id,
            cursor=cursor,
            jenjang=creds.get("jenjang", "sd"),
            course_id=creds.get("course_id"),
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc
    except Exception as exc:
        logger.exception("[notifications] gagal mengambil notifikasi")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Gagal mengambil notifikasi.",
        ) from exc

    return {
        "success": True,
        "message": "Berhasil mengambil notifikasi",
        "data": result,
    }
