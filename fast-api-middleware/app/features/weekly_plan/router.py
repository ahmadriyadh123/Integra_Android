import logging
import io
from fastapi import APIRouter, Depends, HTTPException, status
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
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    try:
        repo = WeeklyPlanRepository(odoo_client)
        service = WeeklyPlanService(repo)

        data = service.get_weekly_plan_list(
            uid=creds["uid"],
            password=creds["password"],
            jenjang=creds.get("jenjang", "sd"),
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
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    try:
        repo = WeeklyPlanRepository(odoo_client)
        service = WeeklyPlanService(repo)

        data = service.get_weekly_plan_detail(
            uid=creds["uid"],
            password=creds["password"],
            plan_id=plan_id,
            jenjang=creds.get("jenjang", "sd")
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
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    """
    Ambil file PDF Weekly Plan dari ir.attachment Odoo dan stream ke mobile.
    Jika attachment belum ada, fallback ke generate PDF via ReportLab.
    """
    try:
        repo = WeeklyPlanRepository(odoo_client)
        service = WeeklyPlanService(repo)

        # Ambil header untuk dapat message_main_attachment_id
        jenjang = creds.get("jenjang", "sd")
        header = repo.get_weekly_plan_by_id(
            uid=creds["uid"],
            password=creds["password"],
            plan_id=plan_id,
            jenjang=jenjang
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

        # ── Fetch PDF dari ir.attachment ─────────────────────────────────────
        att_val = header.get('message_main_attachment_id')
        attachment_id = att_val[0] if isinstance(att_val, list) and att_val else (
            att_val if isinstance(att_val, int) else None
        )

        if not attachment_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="File PDF Weekly Plan belum tersedia. Hubungi admin untuk upload file."
            )

        pdf_bytes = repo.get_attachment_pdf(
            uid=creds["uid"],
            password=creds["password"],
            attachment_id=attachment_id
        )

        if not pdf_bytes:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="File PDF tidak dapat dibaca. Hubungi admin untuk upload ulang."
            )

        logger.info(f"[weekly-plan/pdf/{plan_id}] serve dari ir.attachment id={attachment_id}")

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
