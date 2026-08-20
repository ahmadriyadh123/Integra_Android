# app/features/elearning/router.py
import io
import os
import zipfile
import logging
import base64
import httpx
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import Response, FileResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db, get_current_user_credentials
from app.core.config import settings
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

@router.get("/content/{attachment_id}/{path:path}")
async def download_attachment_content(
    attachment_id: int,
    path: str,
    db: AsyncSession = Depends(get_db)
):
    # Mapping manual ID attachment ke nama file ZIP lokal yang sudah Anda sediakan
    local_files_map = {
        2067: "SCORM_Pendidikan_Agama_Islam_Kelas_1_SD_Kurikulum_Merdeka_Odoo16.zip",
        2061: "SCORM_Matematika_Kelas_1_SD_Kurikulum_Merdeka_Odoo16.zip",
        2062: "SCORM_Bahasa_Inggris_Kelas_1_SD_Kurikulum_Merdeka_Odoo16.zip",
        24: "SCORM_Pendidikan_Pancasila_Kelas_1_SD_Kurikulum_Merdeka_Odoo16.zip",
        26: "SCORM_PJOK_Kelas_1_SD_Kurikulum_Merdeka_Odoo16.zip",
        28: "SCORM_Bahasa_Indonesia_Kelas_1_SD_Kurikulum_Merdeka_Odoo16.zip",
    }

    filename = local_files_map.get(attachment_id)
    if not filename:
        raise HTTPException(status_code=404, detail="File materi tidak terdaftar di server lokal.")

    # Arahkan ke folder penyimpanan lokal FastAPI
    local_dir = os.path.join("app", "static", "scorm_files")
    file_path = os.path.join(local_dir, filename)

    if os.path.exists(file_path):
        return FileResponse(path=file_path, media_type="application/zip", filename=filename)

    raise HTTPException(status_code=404, detail="File fisik ZIP tidak ditemukan di penyimpanan server.")