import logging
import io
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import StreamingResponse
from app.core.dependencies import get_odoo_client, get_current_user_credentials
from app.features.weekly_plan.schemas import (
    APIResponseWeeklyPlanList,
    APIResponseWeeklyPlanDetail
)
from app.features.weekly_plan.repository import WeeklyPlanRepository
from app.features.weekly_plan.service import WeeklyPlanService
from app.features.weekly_plan.pdf_generator import generate_weekly_plan_pdf

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/weekly-plan",
    tags=["Menu Weekly Plan"]
)

@router.get("/list", response_model=APIResponseWeeklyPlanList)
def get_weekly_plans(
    jenjang: Optional[str] = Query(None, description="Jenjang sekolah: sd, smp, tk"),
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    try:
        repo = WeeklyPlanRepository(odoo_client)
        service = WeeklyPlanService(repo)

        selected_jenjang = jenjang or creds.get("jenjang", "sd")
        data = service.get_weekly_plan_list(
            uid=creds["uid"],
            password=creds["password"],
            jenjang=selected_jenjang,
            course_id=creds.get("course_id")  # Dari JWT untuk filter per kelas
        )

        return APIResponseWeeklyPlanList(
            success=True,
            message="Berhasil mengambil daftar Weekly Plan",
            data=data
        )
    except Exception as e:
        logger.error(f"[weekly-plan/list] Error uid={creds['uid']}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil daftar Weekly Plan: {str(e)}"
        )

@router.get("/detail/{plan_id}", response_model=APIResponseWeeklyPlanDetail)
def get_weekly_plan_detail(
    plan_id: int,
    jenjang: Optional[str] = Query(None, description="Jenjang sekolah: sd, smp, tk"),
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    try:
        repo = WeeklyPlanRepository(odoo_client)
        service = WeeklyPlanService(repo)

        selected_jenjang = jenjang or creds.get("jenjang", "sd")
        data = service.get_weekly_plan_detail(
            uid=creds["uid"],
            password=creds["password"],
            plan_id=plan_id,
            jenjang=selected_jenjang
        )

        if not data:
            return APIResponseWeeklyPlanDetail(
                success=False,
                message="Dokumen Weekly Plan tidak ditemukan",
                data=None
            )

        return APIResponseWeeklyPlanDetail(
            success=True,
            message=f"Berhasil mengambil detail Weekly Plan ID {plan_id}",
            data=data
        )
    except Exception as e:
        logger.error(f"[weekly-plan/detail/{plan_id}] Error uid={creds['uid']}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil detail Weekly Plan: {str(e)}"
        )


@router.get("/pdf/{plan_id}")
def get_weekly_plan_pdf(
    plan_id: int,
    jenjang: Optional[str] = Query(None, description="Jenjang sekolah: sd, smp, tk"),
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    """
    Ambil file PDF Weekly Plan dari ir.attachment Odoo dan stream ke mobile.
    Jika attachment belum ada atau gagal dibaca, fallback ke generate PDF via ReportLab.
    """
    try:
        repo = WeeklyPlanRepository(odoo_client)
        service = WeeklyPlanService(repo)

        selected_jenjang = jenjang or creds.get("jenjang", "sd")
        header = repo.get_weekly_plan_by_id(
            uid=creds["uid"],
            password=creds["password"],
            plan_id=plan_id,
            jenjang=selected_jenjang
        )

        if not header:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Weekly Plan ID {plan_id} tidak ditemukan"
            )

        # Nama file untuk Content-Disposition
        from app.features.weekly_plan.service import WeeklyPlanService as _S
        _svc = _S(repo)
        kelas = _svc._parse_many2one(header.get('course_id'), 'SD').replace(' ', '_')
        pekan = str(header.get('pekan') or '').replace(' ', '_').replace('/', '-')
        filename = f"WeeklyPlan_{kelas}_{pekan}.pdf"

        pdf_bytes = None

        att_val = header.get('message_main_attachment_id')
        attachment_id = att_val[0] if isinstance(att_val, list) and att_val else (
            att_val if isinstance(att_val, int) else None
        )

        if attachment_id:
            pdf_bytes = repo.get_attachment_pdf(
                uid=creds["uid"],
                password=creds["password"],
                attachment_id=attachment_id
            )

        # Generate the PDF locally when no stored attachment is available.
        if not pdf_bytes:
            logger.info(f"[weekly-plan/pdf/{plan_id}] fallback ke dynamic ReportLab PDF generator")
            detail_data = service.get_weekly_plan_detail(
                uid=creds["uid"],
                password=creds["password"],
                plan_id=plan_id,
                jenjang=selected_jenjang
            )
            if detail_data:
                pdf_bytes = generate_weekly_plan_pdf(detail_data)

        if not pdf_bytes:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Gagal membuat file PDF Weekly Plan."
            )

        logger.info(f"[weekly-plan/pdf/{plan_id}] serve PDF (size={len(pdf_bytes)} bytes)")

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
        logger.error(f"[weekly-plan/pdf/{plan_id}] Error uid={creds['uid']}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil PDF Weekly Plan: {str(e)}"
        )

