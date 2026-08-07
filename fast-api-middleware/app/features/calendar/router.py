from fastapi import APIRouter, Depends, HTTPException, status
from app.core.dependencies import get_odoo_client, get_current_user_credentials
from app.features.calendar.schemas import APIResponseCalendar
from app.features.calendar.repository import CalendarRepository
from app.features.calendar.service import CalendarService
import logging

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/calendar",
    tags=["Menu Kalender Akademik"]
)

@router.get("/list", response_model=APIResponseCalendar)
def get_academic_calendars(
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    try:
        repo = CalendarRepository(odoo_client)
        service = CalendarService(repo)

        data = service.get_calendars_list(
            uid=creds["uid"],
            password=creds["password"]
        )

        return APIResponseCalendar(
            success=True,
            message="Berhasil mengambil data kalender akademik SD",
            data=data
        )
    except Exception as e:
        logger.error(f"[calendar/list] Error uid={creds['uid']}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil data kalender dari Odoo: {str(e)}"
        )
