from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
import logging

from app.core.dependencies import get_db, get_current_user_credentials
from app.features.calendar.schemas import APIResponseCalendar
from app.features.calendar.repository import CalendarRepository
from app.features.calendar.service import CalendarService

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/calendar",
    tags=["Menu Kalender Akademik"]
)

@router.get("/list", response_model=APIResponseCalendar)
async def get_academic_calendars(
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db)
):
    try:
        repo = CalendarRepository(db)
        service = CalendarService(repo)
        jenjang = creds.get("jenjang", "sd")

        data = await service.get_calendars_list(jenjang=jenjang)

        return APIResponseCalendar(
            success=True,
            message=f"Berhasil mengambil data kalender akademik {jenjang.upper()}",
            data=data
        )
    except Exception as e:
        logger.error(f"[calendar/list] Error uid={creds.get('uid')}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil data kalender: {str(e)}"
        )