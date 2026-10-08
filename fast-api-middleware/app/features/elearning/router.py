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
    APIResponseCourseMessages,
    CreateCourseMessageRequest,
    CompleteSlideRequest,
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
            course_id=course_id,
            partner_id=creds.get("partner_id"),
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


@router.post("/courses/{course_id}/slides/{slide_id}/progress")
def complete_course_slide(
    course_id: int,
    slide_id: int,
    request: CompleteSlideRequest,
    creds: dict = Depends(get_current_user_credentials),
    odoo: OdooRPCClient = Depends(get_odoo_client),
):
    partner_id = creds.get("partner_id")
    if not partner_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Akun ini tidak terhubung dengan data peserta.",
        )
    try:
        service = ElearningService(ElearningRepository(odoo))
        completed = service.mark_slide_completed(
            uid=creds["uid"],
            password=creds["password"],
            course_id=course_id,
            slide_id=slide_id,
            partner_id=int(partner_id),
            source=request.source,
            completion_status=request.completion_status,
        )
        if not completed:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=(
                    "Status selesai tidak cocok dengan tipe materi atau materi "
                    "tidak termasuk dalam kursus ini."
                ),
            )
        return {
            "success": True,
            "message": "Progres materi berhasil disimpan.",
            "data": {"slide_id": slide_id, "is_completed": True},
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(
            "[elearning/courses/%s/slides/%s/progress] Error uid=%s",
            course_id,
            slide_id,
            creds.get("uid"),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal menyimpan progres materi: {str(e)}",
        )


@router.get(
    "/courses/{course_id}/messages",
    response_model=APIResponseCourseMessages,
)
def get_course_messages(
    course_id: int,
    creds: dict = Depends(get_current_user_credentials),
    odoo: OdooRPCClient = Depends(get_odoo_client),
):
    try:
        service = ElearningService(ElearningRepository(odoo))
        data = service.get_course_messages(
            uid=creds["uid"],
            password=creds["password"],
            course_id=course_id,
            partner_id=creds.get("partner_id"),
        )
        if data is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Kursus E-Learning tidak ditemukan.",
            )
        return APIResponseCourseMessages(
            success=True,
            message="Berhasil mengambil diskusi kursus.",
            data=data,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(
            "[elearning/courses/%s/messages] Error uid=%s",
            course_id,
            creds.get("uid"),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil diskusi kursus: {str(e)}",
        )


@router.post("/courses/{course_id}/messages")
def post_course_message(
    course_id: int,
    request: CreateCourseMessageRequest,
    creds: dict = Depends(get_current_user_credentials),
    odoo: OdooRPCClient = Depends(get_odoo_client),
):
    try:
        service = ElearningService(ElearningRepository(odoo))
        message_id = service.post_course_message(
            uid=creds["uid"],
            password=creds["password"],
            course_id=course_id,
            body=request.body,
        )
        if message_id is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Kursus E-Learning tidak ditemukan.",
            )
        return {
            "success": True,
            "message": "Pesan berhasil dikirim.",
            "data": {"id": message_id},
        }
    except HTTPException:
        raise
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(e),
        ) from e
    except Exception as e:
        logger.exception(
            "[elearning/courses/%s/messages] Post error uid=%s",
            course_id,
            creds.get("uid"),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengirim pesan diskusi: {str(e)}",
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