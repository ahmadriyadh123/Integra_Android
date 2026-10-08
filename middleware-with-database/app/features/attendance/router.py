from fastapi import APIRouter, Depends, Query, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
import logging

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
        logger.error(f"[attendance/history] Error uid={creds.get('uid')}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil data presensi: {str(e)}"
        )