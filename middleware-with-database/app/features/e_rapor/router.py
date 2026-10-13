import io
import logging
from urllib.parse import quote

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user_credentials, get_db
from app.features.e_rapor.repository import ERaporRepository
from app.features.e_rapor.schemas import (
    APIResponseReportDetail,
    APIResponseReportList,
)
from app.features.e_rapor.service import ERaporService

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/e-rapor", tags=["Menu E-Rapor"])


def _student_id_from_credentials(creds: dict) -> int:
    student_id = creds.get("student_id")
    if type(student_id) is not int or student_id <= 0:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Data siswa tidak ditemukan dalam sesi Anda.",
        )
    return student_id


def _requested_level(jenjang: str | None, creds: dict) -> str:
    try:
        return ERaporRepository.normalize_level(jenjang or creds.get("jenjang"))
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)
        ) from exc


@router.get("/list", response_model=APIResponseReportList)
async def get_student_reports(
    jenjang: str | None = Query(None, description="Jenjang sekolah: sd, smp, tk"),
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db),
):
    student_id = _student_id_from_credentials(creds)
    level = _requested_level(jenjang, creds)
    try:
        service = ERaporService(ERaporRepository(db))
        reports = await service.get_student_reports(student_id, level)
        return APIResponseReportList(
            success=True,
            message="Berhasil mengambil daftar e-rapor",
            data=reports,
        )
    except HTTPException:
        raise
    except Exception:
        logger.exception("[e-rapor/list] Error uid=%s", creds.get("uid"))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Gagal mengambil data e-rapor.",
        ) from None


@router.get("/list/sync")
async def sync_student_reports(
    cursor: str | None = Query(None),
    jenjang: str | None = Query(None, description="Jenjang sekolah: sd, smp, tk"),
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db),
):
    student_id = _student_id_from_credentials(creds)
    level = _requested_level(jenjang, creds)
    try:
        service = ERaporService(ERaporRepository(db))
        data = await service.sync_student_reports(student_id, level, cursor)
        return {
            "success": True,
            "message": "Berhasil menyinkronkan daftar e-rapor",
            "data": data,
        }
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)
        ) from exc
    except Exception:
        logger.exception("[e-rapor/list/sync] Error uid=%s", creds.get("uid"))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Gagal sinkronisasi daftar e-rapor.",
        ) from None


@router.get("/{rapor_id}", response_model=APIResponseReportDetail)
async def get_report_detail(
    rapor_id: int,
    jenjang: str | None = Query(None, description="Jenjang sekolah: sd, smp, tk"),
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db),
):
    student_id = _student_id_from_credentials(creds)
    level = _requested_level(jenjang, creds)
    try:
        service = ERaporService(ERaporRepository(db))
        report = await service.get_report_detail(rapor_id, student_id, level)
        if report is None:
            return APIResponseReportDetail(
                success=False,
                message=f"Detail E-Rapor ID {rapor_id} tidak ditemukan",
                data=None,
            )
        return APIResponseReportDetail(
            success=True,
            message="Berhasil mengambil detail E-Rapor",
            data=report,
        )
    except Exception:
        logger.exception(
            "[e-rapor/%s] Error uid=%s", rapor_id, creds.get("uid")
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Gagal mengambil detail e-rapor.",
        ) from None


@router.get("/pdf/{rapor_id}")
async def get_rapor_pdf(
    rapor_id: int,
    jenjang: str | None = Query(None, description="Jenjang sekolah: sd, smp, tk"),
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db),
):
    student_id = _student_id_from_credentials(creds)
    level = _requested_level(jenjang, creds)
    try:
        service = ERaporService(ERaporRepository(db))
        result = await service.get_rapor_pdf_bytes(
            rapor_id=rapor_id,
            student_id=student_id,
            jenjang=level,
        )
        if result is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Data E-Rapor tidak ditemukan untuk siswa yang sedang login.",
            )
        pdf_bytes, filename = result
        safe_filename = filename.replace('"', "").replace("\r", "").replace("\n", "")
        return StreamingResponse(
            io.BytesIO(pdf_bytes),
            media_type="application/pdf",
            headers={
                "Content-Disposition": (
                    f"inline; filename*=UTF-8''{quote(safe_filename)}"
                ),
                "Content-Length": str(len(pdf_bytes)),
            },
        )
    except HTTPException:
        raise
    except Exception:
        logger.exception(
            "[e-rapor/pdf/%s] Error uid=%s", rapor_id, creds.get("uid")
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Gagal mengambil PDF rapor.",
        ) from None
