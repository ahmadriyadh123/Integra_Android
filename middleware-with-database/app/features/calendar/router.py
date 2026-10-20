from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException, Query, status
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
    course_id = creds.get("course_id")
    jenjang = creds.get("jenjang", "sd")
    if type(course_id) is not int or course_id <= 0:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Akun belum terhubung ke kelas siswa.",
        )
    try:
        repo = CalendarRepository(db)
        service = CalendarService(repo)
        data = await service.get_calendars_list(
            course_id=course_id,
            jenjang=jenjang,
        )

        return APIResponseCalendar(
            success=True,
            message=f"Berhasil mengambil data kalender akademik {jenjang.upper()}",
            data=data
        )
    except Exception as e:
        logger.exception("[calendar/list] Error uid=%s", creds.get("uid"))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Kalender akademik belum dapat dimuat. Silakan coba lagi.",
        ) from e


@router.get("/sync")
async def sync_academic_calendars(
    cursor: str | None = None,
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db),
):
    course_id = creds.get("course_id")
    jenjang = creds.get("jenjang", "sd")
    if type(course_id) is not int or course_id <= 0:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Akun belum terhubung ke kelas siswa.",
        )

    try:
        parsed_cursor = datetime.fromisoformat(cursor.replace("Z", "+00:00")) if cursor else None
        if parsed_cursor is not None and parsed_cursor.tzinfo is None:
            parsed_cursor = parsed_cursor.replace(tzinfo=timezone.utc)
        calendar_args = {"course_id": course_id, "jenjang": jenjang}
        if parsed_cursor is not None:
            calendar_args["changed_since"] = parsed_cursor - timedelta(seconds=2)
        calendars = await CalendarService(CalendarRepository(db)).get_calendars_list(**calendar_args)
        return {
            "success": True,
            "data": {
                "items": calendars["calendars"],
                "removed_ids": [],
                "next_cursor": datetime.now(timezone.utc).isoformat(),
                "full_sync": parsed_cursor is None,
            },
        }
    except Exception as exc:
        logger.exception("[calendar/sync] Error uid=%s", creds.get("uid"))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Gagal menyinkronkan kalender akademik.",
        ) from exc
