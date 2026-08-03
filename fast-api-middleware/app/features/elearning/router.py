from fastapi import APIRouter, Depends, HTTPException, status
from app.core.dependencies import get_odoo_client, get_current_user_credentials
from app.features.elearning.schemas import (
    APIResponseCourseList,
    APIResponseCourseDetail
)
from app.features.elearning.repository import ElearningRepository
from app.features.elearning.service import ElearningService

router = APIRouter(
    prefix="/elearning",
    tags=["Menu E-Learning"]
)

@router.get("/courses", response_model=APIResponseCourseList)
def get_courses(
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    try:
        repo = ElearningRepository(odoo_client)
        service = ElearningService(repo)

        data = service.get_courses_list(uid=creds["uid"], password=creds["password"])

        return APIResponseCourseList(
            success=True,
            message="Berhasil mengambil daftar kursus E-Learning",
            data=data
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil data kursus dari Odoo: {str(e)}"
        )

@router.get("/courses/{course_id}", response_model=APIResponseCourseDetail)
def get_course_detail(
    course_id: int,
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    try:
        repo = ElearningRepository(odoo_client)
        service = ElearningService(repo)

        data = service.get_course_detail(
            uid=creds["uid"],
            password=creds["password"],
            course_id=course_id
        )

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
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil detail kursus dari Odoo: {str(e)}"
        )