from datetime import datetime, timezone
import logging

from fastapi import APIRouter, Depends, Query, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db, get_current_user_credentials
from app.features.attendance.schemas import APIResponse
from app.features.attendance.repository import AttendanceRepository
from app.features.attendance.service import AttendanceService

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/attendance",
    tags=["Menu Kehadiran"]
)

@router.get("/history", response_model=APIResponse)
async def get_attendance_history(
    limit: int = Query(100, ge=1, le=500),
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db)
):
    student_id = creds.get("student_id")
    
    logger.info(f"[attendance/history] uid={creds.get('uid')} student_id={student_id}")

    if not student_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                "Data siswa tidak ditemukan dalam sesi Anda. "
                "Silakan logout dan login ulang untuk memperbarui sesi."
            )
        )

    try:
        repo = AttendanceRepository(db)
        service = AttendanceService(repo)

        data = await service.get_student_history(
            student_id=student_id,
            limit=limit
        )

        return APIResponse(
            success=True,
            message="Berhasil mengambil riwayat presensi",
            data=data
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(
            "[attendance/history] Error uid=%s",
            creds.get("uid"),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Riwayat presensi belum dapat dimuat. Silakan coba lagi.",
        ) from e


@router.get("/history/sync")
async def sync_attendance_history(
    limit: int = Query(500, ge=1, le=500),
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db),
):
    student_id = creds.get("student_id")
    if not student_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                "Data siswa tidak ditemukan dalam sesi Anda. "
                "Silakan logout dan login ulang untuk memperbarui sesi."
            ),
        )

    try:
        service = AttendanceService(AttendanceRepository(db))
        records = await service.get_student_history(
            student_id=student_id,
            limit=limit,
        )
        return {
            "success": True,
            "data": {
                "items": [record.model_dump(mode="json") for record in records],
                "removed_ids": [],
                "next_cursor": datetime.now(timezone.utc).isoformat(),
                "full_sync": True,
            },
        }
    except HTTPException:
        raise
    except Exception as exc:
        logger.exception(
            "[attendance/history/sync] Error uid=%s",
            creds.get("uid"),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Gagal menyinkronkan riwayat presensi.",
        ) from exc