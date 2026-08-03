from fastapi import APIRouter, Depends, Query, Header, HTTPException, status
from app.core.dependencies import get_odoo_client, get_current_user_credentials
from app.features.attendance.schemas import APIResponse
from app.features.attendance.repository import AttendanceRepository
from app.features.attendance.service import AttendanceService

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
    try:
        repo = AttendanceRepository(odoo_client)
        service = AttendanceService(repo)
        
        data = service.get_student_history(
            uid=creds["uid"], 
            password=creds["password"], 
            limit=limit
        )
        
        return APIResponse(
            success=True,
            message="Berhasil mengambil riwayat presensi",
            data=data
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil data dari Odoo: {str(e)}"
        )