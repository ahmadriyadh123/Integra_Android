import io
import logging
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db, get_current_user_credentials
from app.features.e_rapor.schemas import APIResponseReportList, APIResponseReportDetail
from app.features.e_rapor.repository import ERaporRepository
from app.features.e_rapor.service import ERaporService

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/e-rapor",
    tags=["Menu E-Rapor"]
)

@router.get("/list", response_model=APIResponseReportList)
async def get_student_reports(
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db)
):
    student_id = creds.get("student_id")
    if not student_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Data siswa tidak ditemukan dalam sesi Anda."
        )
    try:
        repo = ERaporRepository(db)
        service = ERaporService(repo)
        data = await service.get_student_reports(student_id=student_id)
        return APIResponseReportList(
            success=True,
            message="Berhasil mengambil daftar e-rapor",
            data=data
        )
    except Exception as e:
        logger.error(f"[e-rapor/list] Error uid={creds.get('uid')}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil data e-rapor: {str(e)}"
        )

@router.get("/{rapor_id}", response_model=APIResponseReportDetail)
async def get_report_detail(
    rapor_id: int,
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db)
):
    """Endpoint detail E-Rapor (Fix 404 Not Found)"""
    student_id = creds.get("student_id")
    if not student_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Data siswa tidak ditemukan dalam sesi Anda."
        )
    try:
        repo = ERaporRepository(db)
        service = ERaporService(repo)
        data = await service.get_report_detail(rapor_id=rapor_id, student_id=student_id)
        if not data:
            return APIResponseReportDetail(
                success=False,
                message=f"Detail E-Rapor ID {rapor_id} tidak ditemukan",
                data=None
            )
        return APIResponseReportDetail(
            success=True,
            message="Berhasil mengambil detail E-Rapor",
            data=data
        )
    except Exception as e:
        logger.error(f"[e-rapor/{rapor_id}] Error uid={creds.get('uid')}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil detail e-rapor: {str(e)}"
        )

@router.get("/pdf/{rapor_id}")
async def get_rapor_pdf(
    rapor_id: int,
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db)
):
    student_id = creds.get("student_id")
    if not student_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Data siswa tidak ditemukan dalam sesi Anda."
        )
    try:
        repo = ERaporRepository(db)
        service = ERaporService(repo)
        result = await service.get_rapor_pdf_bytes(
            rapor_id=rapor_id, student_id=student_id
        )
        if not result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="File PDF rapor tidak ditemukan. Hubungi admin untuk upload file."
            )
        pdf_bytes, filename = result
        return StreamingResponse(
            io.BytesIO(pdf_bytes),
            media_type="application/pdf",
            headers={
                "Content-Disposition": f'inline; filename="{filename}"',
                "Content-Length": str(len(pdf_bytes)),
            }
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[e-rapor/pdf/{rapor_id}] Error uid={creds.get('uid')}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil PDF rapor: {str(e)}"
        )