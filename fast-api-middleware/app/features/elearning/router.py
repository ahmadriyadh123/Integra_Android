import io
import logging
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from app.core.dependencies import (
    get_odoo_client,
    get_current_user_credentials
)
from app.core.config import settings
from app.core.odoo_client import OdooRPCClient
from app.features.elearning.schemas import (
    APIResponseCourseList,
    APIResponseCourseDetail,
)
from app.features.elearning.repository import ElearningRepository
from app.features.elearning.service import ElearningService

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/elearning",
    tags=["Menu E-Learning"]
)

@router.get("/courses", response_model=APIResponseCourseList)
def get_courses(
    creds: dict = Depends(get_current_user_credentials),
    odoo: OdooRPCClient = Depends(get_odoo_client)
):
    try:
        repo = ElearningRepository(odoo)
        service = ElearningService(repo)
        data = service.get_courses_list(
            uid=creds["uid"],
            password=creds["password"],
            partner_id=creds.get("partner_id")
        )
        return APIResponseCourseList(
            success=True,
            message="Berhasil mengambil daftar kursus E-Learning",
            data=data
        )
    except Exception as e:
        logger.error(f"[elearning/courses] Error uid={creds.get('uid')}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil data kursus dari Odoo: {str(e)}"
        )

@router.get("/courses/{course_id}", response_model=APIResponseCourseDetail)
def get_course_detail(
    course_id: int,
    creds: dict = Depends(get_current_user_credentials),
    odoo: OdooRPCClient = Depends(get_odoo_client)
):
    try:
        repo = ElearningRepository(odoo)
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
        logger.error(f"[elearning/courses/{course_id}] Error uid={creds.get('uid')}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil detail kursus dari Odoo: {str(e)}"
        )


@router.get("/content/{slide_id}")
@router.get("/content/slide/{slide_id}")
def get_slide_content(
    slide_id: int,
    creds: dict = Depends(get_current_user_credentials),
    odoo: OdooRPCClient = Depends(get_odoo_client)
):
    try:
        repo = ElearningRepository(odoo)

        slide = repo.get_slide_content(
            uid=creds["uid"],
            password=creds["password"],
            slide_id=slide_id
        )

        if not slide:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Slide E-Learning tidak ditemukan."
            )

        is_scorm = (
            str(slide.get("slide_type") or "").lower() == "scorm"
            or str(slide.get("slide_category") or "").lower() == "scorm"
        )
        url = (
            f"/api/v1/elearning/content/{slide_id}/download"
            if is_scorm
            else repo._slide_download_url(
                slide_type=slide.get("slide_type"),
                filename=slide.get("filename"),
                slide_category=slide.get("slide_category"),
            )
        )

        if not url:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="File materi tidak ditemukan."
            )

        return {
            "success": True,
            "slide_id": slide_id,
            "type": slide.get("slide_type"),
            "url": url,
        }

    except HTTPException:
        raise

    except Exception as e:
        logger.exception(f"[elearning/content/{slide_id}] Error uid={creds.get('uid')}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil konten slide: {str(e)}"
        )


@router.get("/content/{slide_id}/download")
def download_scorm(
    slide_id: int,
    creds: dict = Depends(get_current_user_credentials),
    odoo: OdooRPCClient = Depends(get_odoo_client)
):
    try:
        repo = ElearningRepository(odoo)
        service = ElearningService(repo)
        package = service.get_scorm_package(
            uid=creds["uid"],
            password=creds["password"],
            slide_id=slide_id
        )
        if not package:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Paket SCORM tidak ditemukan pada Odoo."
            )

        content, filename, mimetype = package
        return StreamingResponse(
            io.BytesIO(content),
            media_type=mimetype,
            headers={
                "Content-Disposition": f'attachment; filename="{filename}"',
                "Content-Length": str(len(content)),
            },
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"[elearning/content/{slide_id}/download] Error uid={creds.get('uid')}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengunduh paket SCORM: {str(e)}"
        )