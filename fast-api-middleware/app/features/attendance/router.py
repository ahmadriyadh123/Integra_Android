from fastapi import APIRouter, Depends, Query, Header, HTTPException, status
from app.core.dependencies import get_odoo_client, get_current_user_credentials
from app.features.attendance.schemas import APIResponse
from app.features.attendance.repository import AttendanceRepository
from app.features.attendance.service import AttendanceService
import logging

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/attendance",
    tags=["Menu Kehadiran"]
)

@router.get("/history", response_model=APIResponse)
def get_attendance_history(
    limit: int = Query(100, ge=1, le=500),
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    student_id = creds.get("student_id")
    student_name = creds.get("name", "Siswa")

    # Catat identitas siswa untuk melacak pembatasan data per pengguna.
    logger.info(f"[attendance/history] uid={creds['uid']} student_id={student_id}")

    # Tolak request tanpa student_id agar endpoint tidak mengembalikan semua data.
    if not student_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                "Data siswa tidak ditemukan dalam sesi Anda. "
                "Silakan logout dan login ulang untuk memperbarui sesi."
            )
        )

    try:
        repo = AttendanceRepository(odoo_client)
        service = AttendanceService(repo)
        
        data = service.get_student_history(
            uid=creds["uid"], 
            password=creds["password"],
            student_id=student_id,
            student_name=student_name,
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
        logger.error(f"[attendance/history] Error uid={creds['uid']}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil data dari Odoo: {str(e)}"
        )