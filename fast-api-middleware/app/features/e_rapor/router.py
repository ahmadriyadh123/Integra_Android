import io
import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import StreamingResponse

from app.core.dependencies import get_current_user_credentials, get_odoo_client
from app.core.odoo_client import OdooRPCClient
from app.features.e_rapor.repository import ERaporRepository
from app.features.e_rapor.schemas import APIResponseReportDetail, APIResponseReportList
from app.features.e_rapor.service import ERaporService

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/e-rapor", tags=["Menu E-Rapor"])


@router.get("/list", response_model=APIResponseReportList)
def get_student_reports(
    jenjang: Optional[str] = Query(None, description="Jenjang sekolah: sd, smp, tk (opsional, auto-detect jika kosong)"),
    creds: dict = Depends(get_current_user_credentials),
    odoo_client: OdooRPCClient = Depends(get_odoo_client),
):
    """Daftar E-Rapor siswa per semester"""
    student_id = creds.get("student_id")
    if not student_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Data siswa tidak ditemukan dalam sesi Anda."
        )
    try:
        repo = ERaporRepository(odoo_client)
        service = ERaporService(repo)
        selected_jenjang = jenjang or creds.get("jenjang", "sd")
        data = service.get_student_reports(
            creds["uid"],
            creds["password"],
            student_id,
            jenjang=selected_jenjang
        )
        return APIResponseReportList(
            success=True,
            message="Berhasil mengambil daftar e-rapor",
            data=data
        )
    except Exception as exc:
        logger.exception("[e-rapor/list] Error uid=%s", creds.get("uid"))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil data e-rapor: {str(exc)}"
        ) from exc


@router.get("/{rapor_id}", response_model=APIResponseReportDetail)
def get_report_card_details(
    rapor_id: int,
    jenjang: Optional[str] = Query(None, description="Jenjang sekolah: sd, smp, tk (opsional, auto-detect jika kosong)"),
    creds: dict = Depends(get_current_user_credentials),
    odoo_client: OdooRPCClient = Depends(get_odoo_client),
):
    """Endpoint detail E-Rapor"""
    student_id = creds.get("student_id")
    if not student_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Data siswa tidak ditemukan dalam sesi Anda."
        )
    try:
        repo = ERaporRepository(odoo_client)
        service = ERaporService(repo)
        data = service.get_report_detail(
            creds["uid"],
            creds["password"],
            rapor_id,
            student_id,
            jenjang=jenjang
        )
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
    except Exception as exc:
        logger.exception("[e-rapor/%s] Error uid=%s", rapor_id, creds.get("uid"))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil detail e-rapor: {str(exc)}"
        ) from exc


@router.get("/pdf/{rapor_id}")
def get_rapor_pdf(
    rapor_id: int,
    creds: dict = Depends(get_current_user_credentials),
    odoo_client: OdooRPCClient = Depends(get_odoo_client),
):
    """Endpoint download PDF E-Rapor"""
    student_id = creds.get("student_id")
    if not student_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Data siswa tidak ditemukan dalam sesi Anda."
        )
    try:
        repo = ERaporRepository(odoo_client)
        service = ERaporService(repo)
        result = service.get_rapor_pdf_bytes(
            creds["uid"],
            creds["password"],
            rapor_id=rapor_id,
            student_id=student_id
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
    except Exception as exc:
        logger.exception("[e-rapor/pdf/%s] Error uid=%s", rapor_id, creds.get("uid"))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil PDF rapor: {str(exc)}"
        ) from exc


