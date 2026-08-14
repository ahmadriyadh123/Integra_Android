# app/features/elearning/router.py
import logging
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db, get_current_user_credentials
from app.features.elearning.schemas import APIResponseCourseList, APIResponseCourseDetail
from app.features.elearning.repository import ElearningRepository
from app.features.elearning.service import ElearningService

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/elearning",
    tags=["Menu E-Learning"]
)

@router.get("/courses", response_model=APIResponseCourseList)
async def get_courses(
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db)
):
    try:
        repo = ElearningRepository(db)
        service = ElearningService(repo)
        data = await service.get_courses_list()

        return APIResponseCourseList(
            success=True,
            message="Berhasil mengambil daftar kursus E-Learning",
            data=data
        )
    except Exception as e:
        logger.error(f"[elearning/courses] Error uid={creds.get('uid')}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil data kursus: {str(e)}"
        )

@router.get("/courses/{course_id}", response_model=APIResponseCourseDetail)
async def get_course_detail(
    course_id: int,
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db)
):
    try:
        repo = ElearningRepository(db)
        service = ElearningService(repo)
        data = await service.get_course_detail(course_id=course_id)

        if not data:
            return APIResponseCourseDetail(
                success=False,
                message="Kursus E-Learning tidak ditemukan",
                data=None
            )

        return APIResponseCourseDetail(
            success=True,
            message="Berhasil mengambil detail kursus E-Learning",
            data=data
        )
    except Exception as e:
        logger.error(f"[elearning/courses/{course_id}] Error uid={creds.get('uid')}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil detail kursus: {str(e)}"
        )